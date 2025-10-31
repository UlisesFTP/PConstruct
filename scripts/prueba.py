from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
import time
import re
import json
import csv
from datetime import datetime
import urllib.parse

class MultiStoreScraper:
    def __init__(self):
        self.setup_driver()
        self.stores = {
            'amazon': self.scrape_amazon,
            'mercadolibre': self.scrape_mercadolibre,
            'cyberpuerta': self.scrape_cyberpuerta
        }
        
        self.components = {
            '1': {'name': 'Laptops Gaming', 'keywords': ['laptop gamer', 'laptop gaming']},
            '2': {'name': 'CPU/Procesadores', 'keywords': ['procesador', 'cpu intel', 'amd ryzen']},
            '3': {'name': 'GPU/Tarjetas Gráficas', 'keywords': ['tarjeta grafica', 'gpu nvidia', 'rtx', 'gtx']},
            '4': {'name': 'RAM/Memoria', 'keywords': ['memoria ram', 'ddr4', 'ddr5']},
            '5': {'name': 'Motherboard', 'keywords': ['motherboard', 'tarjeta madre', 'placa madre']},
            '6': {'name': 'Fuente de Poder', 'keywords': ['fuente poder', 'psu', 'power supply']},
            '7': {'name': 'Ventilación/Cooling', 'keywords': ['ventilador pc', 'cooler cpu', 'refrigeracion']},
            '8': {'name': 'Gabinete/Case', 'keywords': ['gabinete pc', 'case gamer', 'torre pc']}
        }
    
    def setup_driver(self):
        """Configurar el driver de Chrome"""
        options = Options()
        options.add_argument("--window-size=1200,800")
        options.add_argument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        options.add_argument("--disable-blink-features=AutomationControlled")
        options.add_argument("--disable-extensions")
        options.add_experimental_option("excludeSwitches", ["enable-automation"])
        options.add_experimental_option('useAutomationExtension', False)
        service = Service(ChromeDriverManager().install())
        self.driver = webdriver.Chrome(service=service, options=options)
        self.driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
    
    def show_menu(self):
        """Mostrar menú de opciones"""
        print("\n" + "="*60)
        print("🛒 MULTI-STORE PC COMPONENTS SCRAPER")
        print("="*60)
        
        print("\n📦 COMPONENTES DISPONIBLES:")
        for key, value in self.components.items():
            print(f"  {key}. {value['name']}")
        
        print("\n🏪 TIENDAS INCLUIDAS:")
        print("  🟡 Amazon México")
        print("  🔵 MercadoLibre México")
        print("  🟢 Cyberpuerta")
        
        return input("\n➤ Selecciona el componente a buscar (1-8): ")
    
    def scrape_amazon(self, search_term, max_pages=3):
        """Scraper para Amazon México"""
        print(f"\n🟡 Buscando en Amazon: {search_term}")
        products = []
        
        try:
            for page in range(1, max_pages + 1):
                url = f"https://www.amazon.com.mx/s?k={urllib.parse.quote(search_term)}&page={page}"
                self.driver.get(url)
                time.sleep(3)
                
                self.driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
                time.sleep(2)
                
                results = self.driver.find_elements(By.CSS_SELECTOR, "[data-component-type='s-search-result']")
                print(f"   Página {page}: {len(results)} productos encontrados")
                
                for result in results:
                    try:
                        full_text = result.text
                        
                        # Precio
                        price_match = re.search(r'\$([0-9,]+)', full_text)
                        price = None
                        if price_match:
                            try:
                                price = float(price_match.group(1).replace(',', ''))
                            except:
                                continue
                        
                        # Nombre
                        lines = [line.strip() for line in full_text.split('\n') if line.strip()]
                        name = None
                        for line in lines:
                            if (len(line) > 15 and 
                                not line.startswith('$') and 
                                not line.isdigit() and
                                'patrocinado' not in line.lower() and
                                'anterior:' not in line.lower()):
                                name = line
                                break
                        
                        # Link
                        link = None
                        try:
                            links = result.find_elements(By.TAG_NAME, "a")
                            for l in links:
                                href = l.get_attribute("href")
                                if href and "/dp/" in href:
                                    link = href
                                    break
                        except:
                            pass
                        
                        if name and price and link:
                            products.append({
                                'name': name,
                                'price': price,
                                'link': link,
                                'store': 'Amazon',
                                'page': page
                            })
                    
                    except Exception as e:
                        continue
                
                if page < max_pages:
                    time.sleep(2)
        
        except Exception as e:
            print(f"   ❌ Error en Amazon: {e}")
        
        print(f"   ✅ Amazon: {len(products)} productos procesados")
        return products
    
    def scrape_mercadolibre(self, search_term, max_pages=3):
        """Scraper para MercadoLibre México - Actualizado 2024"""
        print(f"\n🔵 Buscando en MercadoLibre: {search_term}")
        products = []
        
        try:
            for page in range(1, max_pages + 1):
                # URL actualizada de MercadoLibre
                if page == 1:
                    url = f"https://listado.mercadolibre.com.mx/{search_term.replace(' ', '-')}"
                else:
                    offset = (page - 1) * 48
                    url = f"https://listado.mercadolibre.com.mx/{search_term.replace(' ', '-')}_Desde_{offset + 1}"
                
                print(f"   Navegando a: {url}")
                self.driver.get(url)
                time.sleep(4)
                
                # Scroll para cargar contenido dinámico
                for i in range(3):
                    self.driver.execute_script(f"window.scrollTo(0, {1000 * (i + 1)});")
                    time.sleep(1)
                
                # Buscar productos con múltiples selectores
                products_found = 0
                selectors_to_try = [
                    ".ui-search-result",
                    ".ui-search-results__item", 
                    "[data-testid='result-item']",
                    ".shops__result-wrapper"
                ]
                
                results = []
                for selector in selectors_to_try:
                    try:
                        results = self.driver.find_elements(By.CSS_SELECTOR, selector)
                        if results:
                            print(f"   ✅ Usando selector: {selector}")
                            break
                    except:
                        continue
                
                print(f"   Página {page}: {len(results)} elementos encontrados")
                
                for result in results:
                    try:
                        # Extraer información del producto
                        name = None
                        price = None
                        link = None
                        
                        # Buscar nombre con múltiples selectores
                        name_selectors = [
                            ".poly-component__title a",
                            ".ui-search-item__title a",
                            "h2 a",
                            ".ui-search-item__title-label",
                            ".ui-search-item__brand-discoverability"
                        ]
                        
                        for ns in name_selectors:
                            try:
                                name_elem = result.find_element(By.CSS_SELECTOR, ns)
                                name = name_elem.text.strip()
                                if name and len(name) > 10:
                                    break
                            except:
                                continue
                        
                        # Buscar precio con múltiples selectores
                        price_selectors = [
                            ".andes-money-amount__fraction",
                            ".price-tag-fraction", 
                            ".andes-money-amount--cents-superscript .andes-money-amount__fraction",
                            ".ui-search-price .andes-money-amount__fraction"
                        ]
                        
                        for ps in price_selectors:
                            try:
                                price_elem = result.find_element(By.CSS_SELECTOR, ps)
                                price_text = price_elem.text.replace('.', '').replace(',', '').strip()
                                if price_text.isdigit():
                                    price = float(price_text)
                                    break
                            except:
                                continue
                        
                        # Buscar link
                        link_selectors = [
                            ".poly-component__title a",
                            ".ui-search-item__title a",
                            "h2 a",
                            ".ui-search-result__content a"
                        ]
                        
                        for ls in link_selectors:
                            try:
                                link_elem = result.find_element(By.CSS_SELECTOR, ls)
                                link = link_elem.get_attribute("href")
                                if link and link.startswith('http'):
                                    break
                            except:
                                continue
                        
                        if name and price and link:
                            products.append({
                                'name': name,
                                'price': price,
                                'link': link,
                                'store': 'MercadoLibre',
                                'page': page
                            })
                            products_found += 1
                    
                    except Exception as e:
                        continue
                
                print(f"   ✅ Página {page}: {products_found} productos procesados")
                
                if page < max_pages:
                    time.sleep(3)
        
        except Exception as e:
            print(f"   ❌ Error en MercadoLibre: {e}")
        
        print(f"   ✅ MercadoLibre Total: {len(products)} productos procesados")
        return products
    
    def scrape_cyberpuerta(self, search_term, max_pages=3):
        """Scraper para Cyberpuerta - Actualizado 2024"""
        print(f"\n🟢 Buscando en Cyberpuerta: {search_term}")
        products = []
        
        try:
            for page in range(1, max_pages + 1):
                # URL de búsqueda de Cyberpuerta
                url = f"https://www.cyberpuerta.mx/buscar/?q={urllib.parse.quote(search_term)}"
                if page > 1:
                    url += f"&page={page}"
                
                print(f"   Navegando a: {url}")
                self.driver.get(url)
                time.sleep(5)
                
                # Scroll para cargar productos
                for i in range(4):
                    self.driver.execute_script(f"window.scrollTo(0, {1200 * (i + 1)});")
                    time.sleep(1)
                
                # Buscar productos con múltiples selectores
                products_found = 0
                selectors_to_try = [
                    ".emproduct",
                    ".product-item-info",
                    ".item",
                    ".product-card",
                    ".product-wrapper"
                ]
                
                results = []
                for selector in selectors_to_try:
                    try:
                        results = self.driver.find_elements(By.CSS_SELECTOR, selector)
                        if results:
                            print(f"   ✅ Usando selector: {selector}")
                            break
                    except:
                        continue
                
                print(f"   Página {page}: {len(results)} elementos encontrados")
                
                for result in results:
                    try:
                        name = None
                        price = None
                        link = None
                        
                        # Buscar nombre
                        name_selectors = [
                            ".emproduct_name a",
                            ".product-item-link",
                            ".product-name a",
                            "h2 a",
                            "h3 a"
                        ]
                        
                        for ns in name_selectors:
                            try:
                                name_elem = result.find_element(By.CSS_SELECTOR, ns)
                                name = name_elem.text.strip()
                                if name and len(name) > 10:
                                    link = name_elem.get_attribute("href")  # Obtener link del mismo elemento
                                    break
                            except:
                                continue
                        
                        # Buscar precio
                        price_selectors = [
                            ".price",
                            ".precio-actual",
                            ".emproduct_price",
                            ".product-price",
                            ".money"
                        ]
                        
                        for ps in price_selectors:
                            try:
                                price_elem = result.find_element(By.CSS_SELECTOR, ps)
                                price_text = price_elem.text.replace('$', '').replace(',', '').strip()
                                # Buscar números en el texto
                                numbers = re.findall(r'[\d,]+', price_text)
                                if numbers:
                                    price = float(numbers[0].replace(',', ''))
                                    break
                            except:
                                continue
                        
                        # Validar link
                        if link and not link.startswith('http'):
                            if link.startswith('/'):
                                link = 'https://www.cyberpuerta.mx' + link
                            else:
                                link = None
                        
                        if name and price and link:
                            products.append({
                                'name': name,
                                'price': price,
                                'link': link,
                                'store': 'Cyberpuerta',
                                'page': page
                            })
                            products_found += 1
                    
                    except Exception as e:
                        continue
                
                print(f"   ✅ Página {page}: {products_found} productos procesados")
                
                if page < max_pages:
                    time.sleep(4)
        
        except Exception as e:
            print(f"   ❌ Error en Cyberpuerta: {e}")
        
        print(f"   ✅ Cyberpuerta Total: {len(products)} productos procesados")
        return products
    
    def scrape_all_stores(self, component_choice, max_pages=3):
        """Buscar en todas las tiendas"""
        if component_choice not in self.components:
            print("❌ Opción inválida")
            return []
        
        component = self.components[component_choice]
        print(f"\n🔍 Buscando: {component['name']}")
        print(f"⏰ Iniciado: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        all_products = []
        
        # Buscar en cada tienda con diferentes keywords
        for keyword in component['keywords']:
            print(f"\n🔑 Keyword: '{keyword}'")
            for store_name, scrape_func in self.stores.items():
                try:
                    products = scrape_func(keyword, max_pages)
                    all_products.extend(products)
                    time.sleep(3)  # Pausa entre tiendas
                except Exception as e:
                    print(f"   ❌ Error en {store_name}: {e}")
                    continue
        
        # Eliminar duplicados basándose en nombre y precio similares
        unique_products = self.remove_duplicates(all_products)
        
        return unique_products
    
    def remove_duplicates(self, products):
        """Eliminar productos duplicados"""
        if not products:
            return []
            
        unique = []
        seen = set()
        
        for product in products:
            # Crear una clave única basada en nombre normalizado y precio
            name_key = re.sub(r'[^\w\s]', '', product['name'].lower())[:50]
            key = (name_key, product['price'])
            
            if key not in seen:
                seen.add(key)
                unique.append(product)
        
        duplicates_removed = len(products) - len(unique)
        if duplicates_removed > 0:
            print(f"\n🔄 Eliminados {duplicates_removed} duplicados")
        print(f"✅ Productos únicos: {len(unique)}")
        
        return unique
    
    def analyze_and_save(self, products, component_name):
        """Analizar resultados y guardar archivos"""
        if not products:
            print("❌ No se encontraron productos")
            return
        
        # Ordenar por precio
        products.sort(key=lambda x: x['price'])
        
        print(f"\n📊 ANÁLISIS DE RESULTADOS - {component_name}")
        print("="*60)
        print(f"📦 Total productos: {len(products)}")
        
        # Estadísticas de precios
        prices = [p['price'] for p in products]
        print(f"💰 Precio promedio: ${sum(prices)/len(prices):,.0f}")
        print(f"💰 Precio más bajo: ${min(prices):,.0f}")
        print(f"💰 Precio más alto: ${max(prices):,.0f}")
        
        # Por tienda
        by_store = {}
        for product in products:
            store = product['store']
            by_store[store] = by_store.get(store, 0) + 1
        
        print(f"\n🏪 PRODUCTOS POR TIENDA:")
        for store, count in sorted(by_store.items(), key=lambda x: x[1], reverse=True):
            percentage = (count / len(products)) * 100
            print(f"   {store}: {count} productos ({percentage:.1f}%)")
        
        # Top 15 productos más baratos
        print(f"\n🏆 TOP 15 MÁS BARATOS:")
        for i, product in enumerate(products[:15], 1):
            store_emoji = {"Amazon": "🟡", "MercadoLibre": "🔵", "Cyberpuerta": "🟢"}
            emoji = store_emoji.get(product['store'], '⚪')
            print(f"{i:2d}. {emoji} ${product['price']:>8,.0f} - {product['name'][:55]}...")
        
        # Guardar archivos
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        safe_name = re.sub(r'[^\w\s-]', '', component_name).replace(' ', '_')
        
        # JSON
        json_filename = f'{safe_name}_{timestamp}.json'
        with open(json_filename, 'w', encoding='utf-8') as f:
            json.dump(products, f, indent=2, ensure_ascii=False)
        
        # CSV
        csv_filename = f'{safe_name}_{timestamp}.csv'
        with open(csv_filename, 'w', newline='', encoding='utf-8-sig') as f:
            if products:
                writer = csv.DictWriter(f, fieldnames=['name', 'price', 'store', 'link', 'page'])
                writer.writeheader()
                for product in products:
                    writer.writerow(product)
        
        print(f"\n💾 ARCHIVOS GUARDADOS:")
        print(f"📄 {json_filename}")
        print(f"📄 {csv_filename}")
        
        return products
    
    def run(self):
        """Ejecutar el scraper principal"""
        try:
            choice = self.show_menu()
            
            if choice in self.components:
                print(f"\n⚙️  Configuración:")
                max_pages = int(input("➤ Páginas por tienda (recomendado 2-3): ") or "3")
                
                # Ejecutar scraping
                products = self.scrape_all_stores(choice, max_pages)
                
                if products:
                    # Analizar y guardar
                    component_name = self.components[choice]['name']
                    self.analyze_and_save(products, component_name)
                    
                    print(f"\n🎉 ¡Scraping completado exitosamente!")
                    print(f"✅ {len(products)} productos únicos encontrados para {component_name}")
                else:
                    print("\n❌ No se encontraron productos en ninguna tienda")
                    print("💡 Intenta con:")
                    print("   - Menos páginas por tienda")
                    print("   - Términos de búsqueda más específicos")
                    print("   - Verificar conexión a internet")
                
            else:
                print("❌ Opción inválida. Selecciona un número del 1 al 8.")
        
        except KeyboardInterrupt:
            print("\n⏹️  Scraping interrumpido por el usuario")
        except Exception as e:
            print(f"\n❌ Error general: {e}")
        finally:
            self.cleanup()
    
    def cleanup(self):
        """Limpiar recursos"""
        try:
            self.driver.quit()
            print("🔒 Navegador cerrado")
        except:
            pass

if __name__ == "__main__":
    print("🚀 Iniciando Multi-Store PC Components Scraper...")
    scraper = MultiStoreScraper()
    scraper.run()