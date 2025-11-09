# PConstruct/services/pricing/app/scraper.py
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
import asyncio # <-- Importante
import re
import logging
import urllib.parse
from typing import Dict, List, Optional

logger = logging.getLogger(__name__)

# Opciones de Chrome optimizadas para Docker/headless
def get_chrome_options():
    options = Options()
    options.add_argument("--headless=new") # <-- Modo headless moderno
    options.add_argument("--no-sandbox") # Necesario en entornos Linux/Docker
    options.add_argument("--disable-dev-shm-usage") # Evita problemas de memoria compartida
    options.add_argument("--window-size=1200,800")
    options.add_argument("--disable-gpu")
    options.add_argument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    options.add_argument("--disable-blink-features=AutomationControlled")
    options.add_experimental_option("excludeSwitches", ["enable-automation"])
    options.add_experimental_option('useAutomationExtension', False)
    # Deshabilitar logs de DevTools que llenan la consola
    options.add_experimental_option('excludeSwitches', ['enable-logging'])
    options.add_argument('--log-level=3') # Solo mostrar errores fatales
    return options

class MultiStoreScraper:
    def __init__(self):
        # El driver se inicializará bajo demanda
        self.driver = None
        self.stores = {
            'amazon': self.scrape_amazon,
            'mercadolibre': self.scrape_mercadolibre,
            'cyberpuerta': self.scrape_cyberpuerta
        }

    def _setup_driver(self):
        """Configurar el driver de Chrome"""
        if self.driver is None:
            try:
                logger.info("Attempting to initialize WebDriver...")
                # Instalar/Cachear el driver
                driver_path = ChromeDriverManager().install()
                service = Service(driver_path)
                self.driver = webdriver.Chrome(service=service, options=get_chrome_options())
                # Script para evitar detección de bot
                self.driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
                logger.info("WebDriver for Chrome initialized successfully.")
            except Exception as e:
                logger.error(f"Error initializing WebDriver: {e}", exc_info=True)
                self.driver = None # Asegurarse que es None si falla
                raise # Re-lanzar para que la tarea de scraping falle

    def _close_driver(self):
        if self.driver:
            try:
                self.driver.quit()
                logger.info("WebDriver closed.")
            except Exception as e:
                logger.error(f"Error closing WebDriver: {e}")
            self.driver = None

    # --- SCRAPERS ASÍNCRONOS ---

    async def scrape_amazon(self, search_term, max_pages=1) -> List[Dict]:
        """Scraper para Amazon México (Async)"""
        logger.info(f"🟡 Buscando en Amazon: {search_term}")
        products = []
        try:
            self._setup_driver() # Configura el driver para esta tarea
            if not self.driver: return []

            for page in range(1, max_pages + 1):
                url = f"https://www.amazon.com.mx/s?k={urllib.parse.quote(search_term)}&page={page}"
                logger.info(f"   Navegando a: {url}")
                self.driver.get(url)
                await asyncio.sleep(4) # Espera un poco más

                # Intenta hacer scroll
                try:
                    self.driver.execute_script("window.scrollTo(0, document.body.scrollHeight * 0.8);")
                    await asyncio.sleep(2)
                except Exception as scroll_err:
                    logger.warning(f"   Scroll en Amazon falló (continuando): {scroll_err}")

                results = self.driver.find_elements(By.CSS_SELECTOR, "[data-component-type='s-search-result']")

                logger.info(f"   Amazon Página {page}: {len(results)} elementos encontrados")

                processed_count = 0
                for result in results:
                    try:
                        name = None
                        price = None
                        link = None
                        full_text = result.text # Obtener todo el texto para el precio

                        # Precio (buscar formato $XXX,XXX.XX o $XXX,XXX)
                        price_match = re.search(r'\$([0-9,]+\.?\d*)', full_text)
                        if price_match:
                            try:
                                price = float(price_match.group(1).replace(',', ''))
                            except ValueError:
                                pass # Ignorar si no se puede convertir

                        # Nombre (Buscar en varios lugares comunes)
                        name_selectors = ["h2 a span", ".a-size-medium.a-color-base.a-text-normal"]
                        for selector in name_selectors:
                            try:
                                name_elem = result.find_element(By.CSS_SELECTOR, selector)
                                if name_elem and name_elem.text:
                                    name = name_elem.text.strip()
                                    break # Tomar el primero encontrado
                            except: continue

                        # Link (Buscar el enlace principal del producto)
                        try:
                            link_elem = result.find_element(By.CSS_SELECTOR, "h2 a.a-link-normal")
                            link = link_elem.get_attribute('href')
                            # Asegurarse que es un link de producto
                            if link and not ('/dp/' in link or '/gp/' in link):
                                link = None
                        except: pass

                        if name and price and link:
                            products.append({
                                'name': name,
                                'price': price,
                                'link': link,
                                'store': 'Amazon',
                            })
                            processed_count += 1

                    except Exception as item_err:
                        # logger.warning(f"   Error procesando item de Amazon: {item_err}") # Descomentar para debug
                        continue

                logger.info(f"   Amazon Página {page}: {processed_count} productos válidos procesados.")
                if page < max_pages:
                    await asyncio.sleep(3) # Pausa entre páginas

        except Exception as e:
            logger.error(f"   ❌ Error general en scrape_amazon: {e}", exc_info=True) # exc_info para más detalle
        finally:
            self._close_driver() # Cierra el driver al final de esta tarea

        logger.info(f"   ✅ Amazon: {len(products)} productos totales encontrados.")
        return products

    async def scrape_mercadolibre(self, search_term, max_pages=1) -> List[Dict]:
        """Scraper para MercadoLibre México (Async)"""
        logger.info(f"🔵 Buscando en MercadoLibre: {search_term}")
        products = []
        try:
            self._setup_driver()
            if not self.driver: return []

            for page in range(1, max_pages + 1):
                if page == 1:
                    url = f"https://listado.mercadolibre.com.mx/{search_term.replace(' ', '-')}"
                else:
                    offset = (page - 1) * 48
                    url = f"https://listado.mercadolibre.com.mx/{search_term.replace(' ', '-')}_Desde_{offset + 1}"

                logger.info(f"   Navegando a: {url}")
                self.driver.get(url)
                await asyncio.sleep(5) # ML puede tardar en cargar

                # Scroll
                try:
                    for i in range(2):
                        self.driver.execute_script(f"window.scrollTo(0, document.body.scrollHeight * {(i+1)*0.4});")
                        await asyncio.sleep(1.5)
                except Exception as scroll_err:
                    logger.warning(f"   Scroll en ML falló (continuando): {scroll_err}")

                item_selectors = [".ui-search-result__wrapper", ".shops__result-wrapper", ".ui-search-layout__item"]
                results = []
                for selector in item_selectors:
                    try:
                        results = self.driver.find_elements(By.CSS_SELECTOR, selector)
                        if results:
                            logger.info(f"   ✅ Usando selector ML: {selector}")
                            break
                    except: continue

                logger.info(f"   ML Página {page}: {len(results)} elementos encontrados")
                processed_count = 0
                for result in results:
                     try:
                        name = None
                        price = None
                        link = None

                        name_selectors = [".ui-search-item__title", "h2.ui-search-item__title"]
                        for selector in name_selectors:
                            try:
                                name_elem = result.find_element(By.CSS_SELECTOR, selector)
                                if name_elem and name_elem.text:
                                    name = name_elem.text.strip()
                                    break
                            except: continue

                        price_selectors = [".andes-money-amount__fraction", ".ui-search-price__second-line .andes-money-amount__fraction"]
                        for selector in price_selectors:
                             try:
                                price_elem = result.find_element(By.CSS_SELECTOR, selector)
                                price_text = price_elem.text.replace('.', '').replace(',', '').strip()
                                if price_text.isdigit():
                                    price = float(price_text)
                                    break
                             except: continue

                        try:
                            link_elem = result.find_element(By.CSS_SELECTOR, "a.ui-search-link, a.shops__items-group-details")
                            link = link_elem.get_attribute('href')
                        except: pass

                        if name and price and link:
                            products.append({
                                'name': name,
                                'price': price,
                                'link': link,
                                'store': 'MercadoLibre',
                            })
                            processed_count += 1
                     except Exception as item_err:
                         # logger.warning(f"   Error procesando item de ML: {item_err}")
                         continue

                logger.info(f"   ML Página {page}: {processed_count} productos válidos procesados.")
                if page < max_pages:
                    await asyncio.sleep(4)

        except Exception as e:
            logger.error(f"   ❌ Error general en scrape_mercadolibre: {e}", exc_info=True)
        finally:
            self._close_driver()

        logger.info(f"   ✅ MercadoLibre Total: {len(products)} productos totales encontrados.")
        return products

    async def scrape_cyberpuerta(self, search_term, max_pages=1) -> List[Dict]:
        """Scraper para Cyberpuerta (Async)"""
        logger.info(f"🟢 Buscando en Cyberpuerta: {search_term}")
        products = []
        try:
            self._setup_driver()
            if not self.driver: return []

            for page in range(1, max_pages + 1):
                url = f"https://www.cyberpuerta.mx/index.php?cl=search&searchparam={urllib.parse.quote(search_term)}"
                if page > 1:
                    url += f"&pgNr={page-1}"

                logger.info(f"   Navegando a: {url}")
                self.driver.get(url)
                await asyncio.sleep(5)

                try:
                    for i in range(3):
                        self.driver.execute_script(f"window.scrollTo(0, document.body.scrollHeight * {(i+1)*0.3});")
                        await asyncio.sleep(1.5)
                except Exception as scroll_err:
                     logger.warning(f"   Scroll en Cyberpuerta falló (continuando): {scroll_err}")

                item_selectors = [".emproduct", ".productdetails"]
                results = []
                for selector in item_selectors:
                    try:
                        results = self.driver.find_elements(By.CSS_SELECTOR, selector)
                        if results:
                            logger.info(f"   ✅ Usando selector CP: {selector}")
                            break
                    except: continue

                logger.info(f"   Cyberpuerta Página {page}: {len(results)} elementos encontrados")
                processed_count = 0
                for result in results:
                     try:
                        name = None
                        price = None
                        link = None

                        name_selectors = [".emproduct_right_title a", ".productData a h1", ".cat_list--title"]
                        for selector in name_selectors:
                            try:
                                name_elem = result.find_element(By.CSS_SELECTOR, selector)
                                if name_elem and name_elem.text:
                                    name = name_elem.text.strip()
                                    try: link = name_elem.get_attribute('href')
                                    except: pass
                                    break
                            except: continue

                        price_selectors = [".emproduct_right_price_left", "#productPrice", ".price", ".cat_list--price"]
                        for selector in price_selectors:
                            try:
                                price_elem = result.find_element(By.CSS_SELECTOR, selector)
                                price_text = price_elem.text.replace('$', '').replace(',', '').strip()
                                price_match = re.search(r'([\d,]+\.?\d*)', price_text)
                                if price_match:
                                    price = float(price_match.group(1).replace(',', ''))
                                    break
                            except: continue

                        if not link:
                            try:
                                link_elem = result.find_element(By.CSS_SELECTOR, "a")
                                link = link_elem.get_attribute('href')
                            except: pass

                        if link and not link.startswith('http'):
                            if link.startswith('/'):
                                link = 'https://www.cyberpuerta.mx' + link
                            else: link = None

                        if name and price and link:
                            products.append({
                                'name': name,
                                'price': price,
                                'link': link,
                                'store': 'Cyberpuerta',
                            })
                            processed_count += 1
                     except Exception as item_err:
                         # logger.warning(f"   Error procesando item de CP: {item_err}")
                         continue

                logger.info(f"   Cyberpuerta Página {page}: {processed_count} productos válidos procesados.")
                if page < max_pages:
                    await asyncio.sleep(4)

        except Exception as e:
            logger.error(f"   ❌ Error general en scrape_cyberpuerta: {e}", exc_info=True)
        finally:
            self._close_driver()

        logger.info(f"   ✅ Cyberpuerta Total: {len(products)} productos totales encontrados.")
        return products

    async def scrape_all_stores(self, search_term: str) -> Dict[str, List[Dict]]:
        amazon = await self.scrape_amazon(search_term)
        ml = await self.scrape_mercadolibre(search_term)
        cp = await self.scrape_cyberpuerta(search_term)

        return {
            "Amazon": amazon if isinstance(amazon, list) else [],
            "MercadoLibre": ml if isinstance(ml, list) else [],
            "Cyberpuerta": cp if isinstance(cp, list) else [],
        }


# --- Instancia y Función Helper ---

# !!! ESTA ES LA FUNCIÓN QUE IMPORTA crud.py !!!
async def get_prices_for_component(search_term: str) -> Dict[str, List[Dict]]:
    """
    Función helper que crea una instancia de Scraper y busca precios.
    """
    # Se crea una instancia nueva cada vez
    scraper_instance = MultiStoreScraper()
    try:
        results = await scraper_instance.scrape_all_stores(search_term)
    except Exception as e:
        logger.error(f"Error fatal durante scrape_all_stores para '{search_term}': {e}", exc_info=True)
        # Asegurarse de cerrar el driver si hubo un error grave aquí
        # (Aunque _close_driver() debería llamarse en finally dentro de cada scrape_X)
        return {'Amazon': [], 'MercadoLibre': [], 'Cyberpuerta': []} # Devolver vacío en error fatal
    return results

# --- Bloque opcional para pruebas directas ---
# if __name__ == "__main__":
#    # Configura logging básico para ver mensajes al ejecutar directamente
#    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
#
#    async def test_run():
#        search = "Ryzen 5 5600X" # Ejemplo de búsqueda
#        print(f"--- Probando scraper para: {search} ---")
#        prices = await get_prices_for_component(search)
#        print("\n--- Resultados ---")
#        import json
#        print(json.dumps(prices, indent=2, ensure_ascii=False))
#        print("------------------")
#
#    asyncio.run(test_run())


