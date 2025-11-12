import asyncio
import time
import re
import json
import urllib.parse
import logging
from datetime import datetime
from decimal import Decimal

# --- Imports de Selenium (Copiados de tu scrapper.py) ---
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager

# --- Imports de Sklearn (Copiados de tu scrapper.py) ---
try:
    from sklearn.feature_extraction.text import TfidfVectorizer
    from sklearn.naive_bayes import MultinomialNB
    from sklearn.pipeline import Pipeline
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False

# --- Imports de NUESTRA APLICACIÓN ---
from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.crud import crud_scraper
from app.schemas.component import ComponentCreate
from app.schemas.offer import OfferCreate
from app.services.cache_service import init_redis, close_redis, invalidate_cache

logging.basicConfig(level=logging.WARNING)

# -------------------------------------------------------------------
# 1. CLASE PCComponentFilter (COPIADA 1:1 DE TU scrapper.py)
# -------------------------------------------------------------------
# (Esta clase es perfecta, no necesita cambios)
class PCComponentFilter:
    """Filtro inteligente para identificar componentes de PC"""
    
    def __init__(self, component_type=None):
        self.component_type = component_type
        self.model = None
        self.use_ml = SKLEARN_AVAILABLE
        
        # MARCAS OBLIGATORIAS por tipo de componente
        self.required_brands = {
            'cpu': {
                'primary': ['intel', 'amd'],
                'cpu_lines': ['ryzen', 'core i', 'xeon', 'pentium', 'celeron', 'athlon', 'threadripper']
            },
            'gpu': {
                'primary': ['nvidia', 'amd', 'radeon', 'geforce'],
                'manufacturers': ['msi', 'asus', 'gigabyte', 'evga', 'zotac', 'palit', 'gainward', 
                                'pny', 'powercolor', 'sapphire', 'xfx', 'asrock', 'inno3d'],
                'series': ['rtx', 'gtx', 'rx ', 'radeon']
            },
            'ram': {
                'brands': ['corsair', 'kingston', 'gskill', 'g.skill', 'hyperx', 'crucial', 
                          'ballistix', 'teamgroup', 'team group', 'adata', 'patriot', 'mushkin'],
                'types': ['ddr4', 'ddr5', 'ddr3']
            },
            'motherboard': {
                'brands': ['asus', 'msi', 'gigabyte', 'asrock', 'evga', 'biostar', 'supermicro'],
                'types': ['motherboard', 'placa madre', 'tarjeta madre', 'mainboard']
            },
            'storage': {
                'brands': ['samsung', 'western digital', 'wd', 'seagate', 'crucial', 'kingston',
                          'sandisk', 'corsair', 'intel', 'sabrent', 'mushkin', 'adata', 'teamgroup'],
                'types': ['ssd', 'nvme', 'hdd', 'disco duro', 'disco sólido', 'm.2', 'sata']
            },
            'psu': {
                'brands': ['corsair', 'evga', 'seasonic', 'thermaltake', 'cooler master', 
                          'be quiet', 'antec', 'silverstone', 'fsp', 'xpg', 'nzxt', 'asus'],
                'types': ['fuente poder', 'power supply', 'psu']
            },
            'cooling': {
                'brands': ['noctua', 'cooler master', 'corsair', 'arctic', 'be quiet', 
                          'deepcool', 'thermaltake', 'nzxt', 'aio', 'ekwb', 'id-cooling'],
                'types': ['cooler', 'ventilador', 'fan', 'refrigeracion', 'disipador', 'aio', 'liquid']
            },
            'gabinete': {
                'brands': ['nzxt', 'corsair', 'cooler master', 'thermaltake', 'lian li',
                          'phanteks', 'fractal design', 'be quiet', 'deepcool', 'montech'],
                'types': ['gabinete', 'gabinete', 'torre', 'chassis']
            },
            'fan': {
                'brands': ['noctua', 'arctic', 'corsair', 'be quiet', 'cooler master',
                          'thermaltake', 'nzxt', 'deepcool', 'phanteks'],
                'types': ['ventilador', 'fan', '120mm', '140mm', 'rgb fan']
            },
            'os': {
                'brands': ['microsoft', 'windows', 'linux', 'ubuntu'],
                'types': ['windows 10', 'windows 11', 'sistema operativo', 'operating system']
            },
            'laptop': {
                'brands': ['asus', 'msi', 'acer', 'hp', 'dell', 'lenovo', 'razer', 'alienware',
                          'gigabyte', 'lg', 'samsung', 'huawei'],
                'types': ['laptop', 'notebook', 'portátil']
            }
        }
        
        # Palabras clave negativas
        self.negative_keywords = [
            'procesador de alimento', 'picadora', 'batidora', 'licuadora',
            'bebé', 'baby', 'infantil', 'niño',
            'escáner automotriz', 'obd', 'obd2',
            'electrodoméstico', 'refrigerador', 'lavadora',
            'aceite', 'oil', 'castrol', 'lubricante',
            'guitarra', 'amplificador', 'fender',
            'sea-doo', 'bobina de encendido', 'jet ski',
            'juguete', 'ropa', 'zapatos', 'mueble'
        ]
        
        if self.use_ml:
            self._train_model()
    
    def _train_model(self):
        """Entrenar modelo básico de ML"""
        training_texts = [
            "Intel Core i7-13700K Processor", "AMD Ryzen 9 7950X",
            "NVIDIA GeForce RTX 4080", "Corsair Vengeance 32GB DDR4",
            "ASUS ROG Strix Motherboard", "Samsung 980 PRO 1TB NVMe",
            "Procesador de Alimentos", "Batidora Manual", "Aceite Castrol GTX"
        ]
        training_labels = [1, 1, 1, 1, 1, 1, 0, 0, 0]
        
        try:
            self.model = Pipeline([
                ('tfidf', TfidfVectorizer(max_features=500, ngram_range=(1, 2))),
                ('clf', MultinomialNB(alpha=0.1))
            ])
            self.model.fit(training_texts, training_labels)
        except:
            self.use_ml = False
    
    def _check_required_brands(self, text, component_type):
        """Verificar marcas requeridas según tipo de componente"""
        if not component_type or component_type not in self.required_brands:
            return True, "No requiere verificación"
        
        text_lower = text.lower()
        requirements = self.required_brands[component_type]
        
        # Accesorios a rechazar por categoría
        accessory_keywords = {
            'cpu': ['caja de cpu', 'carcasa protectora', 'kit de montaje', 'marco de contacto',
                   'soporte', 'bracket', 'hebilla', 'ventilador de cpu', 'bandeja', 'tray'],
            'gpu': ['ventilador de refrigeración', 'ventilador de tarjeta', 'cooling fan',
                   'cable', 'riser', 'bracket', 'soporte', 'backplate', 'adaptador', 'puente'],
            'storage': ['adaptador', 'bracket', 'caddy', 'carcasa externa', 'cable sata'],
            'cooling': ['ventilador repuesto', 'replacement fan', 'fan only'],
            'gabinete': ['ventilador', 'fan', 'rgb strip', 'led strip'],
            'laptop': ['cargador', 'charger', 'batería', 'battery', 'teclado', 'mouse']
        }
        
        # Verificar si es accesorio
        if component_type in accessory_keywords:
            accessories = accessory_keywords[component_type]
            is_accessory = any(acc in text_lower for acc in accessories)
            if is_accessory:
                return False, f"❌ Es accesorio, no {component_type} completo"
        
        # Verificación específica por tipo
        if component_type == 'cpu':
            has_primary = any(brand in text_lower for brand in requirements['primary'])
            has_cpu_line = any(line in text_lower for line in requirements.get('cpu_lines', []))
            indicators = ['procesador', 'processor', 'ghz', 'cores', 'núcleos']
            has_indicator = any(ind in text_lower for ind in indicators)
            
            if not has_primary:
                return False, "❌ No es Intel ni AMD"
            if not has_indicator:
                return False, "❌ Sin indicadores de CPU completo"
            return True, "✅ CPU válido"
        
        elif component_type == 'gpu':
            has_primary = any(brand in text_lower for brand in requirements['primary'])
            has_series = any(series in text_lower for series in requirements.get('series', []))
            indicators = ['tarjeta gráfica', 'graphics card', 'gb gddr', 'vram']
            has_indicator = any(ind in text_lower for ind in indicators)
            
            if not (has_primary or has_series):
                return False, "❌ No es GPU NVIDIA/AMD"
            if not has_indicator:
                return False, "❌ Sin indicadores de GPU completa"
            return True, "✅ GPU válida"
        
        elif component_type == 'ram':
            has_brand = any(brand in text_lower for brand in requirements.get('brands', []))
            has_type = any(ddr in text_lower for ddr in requirements.get('types', []))
            
            if not has_type:
                return False, "❌ No especifica DDR"
            return True, "✅ RAM válida"
        
        elif component_type == 'storage':
            has_brand = any(brand in text_lower for brand in requirements.get('brands', []))
            has_type = any(stype in text_lower for stype in requirements.get('types', []))
            indicators = ['gb', 'tb', 'terabyte', 'gigabyte']
            has_indicator = any(ind in text_lower for ind in indicators)
            
            if not (has_type and has_indicator):
                return False, "❌ Sin tipo de almacenamiento"
            return True, "✅ Almacenamiento válido"
        
        elif component_type == 'psu':
            has_brand = any(brand in text_lower for brand in requirements.get('brands', []))
            has_type = any(ptype in text_lower for ptype in requirements.get('types', []))
            indicators = ['watts', 'w ', '80 plus', 'modular']
            has_indicator = any(ind in text_lower for ind in indicators)
            
            if not (has_brand or has_type):
                return False, "❌ Sin marca de PSU"
            return True, "✅ PSU válida"
        
        elif component_type in ['cooling', 'gabinete', 'fan', 'motherboard']:
            has_brand = any(brand in text_lower for brand in requirements.get('brands', []))
            has_type = any(ctype in text_lower for ctype in requirements.get('types', []))
            
            if not (has_brand or has_type):
                return False, f"❌ Sin marca de {component_type}"
            return True, f"✅ {component_type} válido"
        
        elif component_type == 'laptop':
            has_brand = any(brand in text_lower for brand in requirements.get('brands', []))
            indicators = ['laptop', 'notebook', 'intel', 'amd', 'ryzen', 'core i', 'gb ram']
            has_indicator = any(ind in text_lower for ind in indicators)
            
            if not has_brand:
                return False, "❌ Sin marca de laptop"
            if not has_indicator:
                return False, "❌ Sin indicadores de laptop"
            return True, "✅ Laptop válida"
        
        elif component_type == 'os':
            indicators = ['windows', 'microsoft', 'sistema operativo', 'licencia']
            has_indicator = any(ind in text_lower for ind in indicators)
            
            if not has_indicator:
                return False, "❌ No es sistema operativo"
            return True, "✅ OS válido"
        
        return True, "✅ Válido"
    
    def is_valid(self, product_name, component_type=None):
        """Determinar si un producto es válido"""
        if component_type:
            self.component_type = component_type
        
        # Verificar marcas requeridas
        brand_valid, brand_reason = self._check_required_brands(product_name, self.component_type)
        
        if not brand_valid:
            return False, -100, 0.0
        
        # Verificar palabras negativas
        text_lower = product_name.lower()
        for negative in self.negative_keywords:
            if negative in text_lower:
                return False, -50, 0.0
        
        return True, 10, 1.0


# -------------------------------------------------------------------
# 2. CLASE MultiStoreScraper (MODIFICADA)
# -------------------------------------------------------------------
class MultiStoreScraper:
    
    # --- MODIFICADO: Aceptar la sesión de DB ---
    def __init__(self, db: Session):
        self.driver = None
        self.db = db # <-- Guardamos la sesión de DB
        self.setup_driver()
        
        # TODAS LAS CATEGORÍAS (Copiado 1:1)
        self.components = {
            'CPU': {
                'keywords': ['procesador intel', 'cpu amd ryzen', 'intel core'],
                'filter_type': 'cpu'
            },
            'GPU': {
                'keywords': ['tarjeta grafica nvidia', 'gpu rtx', 'amd radeon'],
                'filter_type': 'gpu'
            },
            'RAM': {
                'keywords': ['memoria ram ddr4', 'memoria ram ddr5'],
                'filter_type': 'ram'
            },
            'Motherboard': {
                'keywords': ['motherboard', 'placa madre'],
                'filter_type': 'motherboard'
            },
            'SSD': {
                'keywords': ['ssd nvme', 'disco solido', 'ssd sata'],
                'filter_type': 'storage'
            },
            'HDD': {
                'keywords': ['disco duro hdd', 'hard drive'],
                'filter_type': 'storage'
            },
            'PSU': {
                'keywords': ['fuente poder', 'power supply'],
                'filter_type': 'psu'
            },
            'Cooling': {
                'keywords': ['cooler cpu', 'refrigeracion liquida'],
                'filter_type': 'cooling'
            },
            'Gabinete': {
                'keywords': ['gabinete pc', 'gabinete gamer'],
                'filter_type': 'gabinete'
            },
            'Ventiladores': {
                'keywords': ['ventilador pc 120mm', 'rgb fan'],
                'filter_type': 'fan'
            },
            'Sistema_Operativo': {
                'keywords': ['windows 11', 'windows 10'],
                'filter_type': 'os'
            },
            'Laptop': {
                'keywords': ['laptop', 'notebook'],
                'filter_type': 'laptop'
            },
            'Laptop_Gamer': {
                'keywords': ['laptop gamer', 'gaming laptop'],
                'filter_type': 'laptop'
            }
        }
        
        self.component_filter = PCComponentFilter()
        print("✅ Filtro inteligente activado")
    
    # (setup_driver - Copiado 1:1)
    def setup_driver(self):
        """Configurar Chrome"""
        options = Options()
        options.add_argument("--headless=new")
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--disable-gpu")
        options.add_argument("--window-size=1920,1080")
        options.add_argument("--log-level=3")
        options.add_argument("--silent")
        options.add_experimental_option('excludeSwitches', ['enable-logging'])
        options.add_argument("--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        
        try:
            # --- ¡INICIO DE CORRECCIÓN! ---
            # Ya no usamos webdriver-manager.
            # Apuntamos directamente al driver que instalamos en el Dockerfile.
            service = Service(executable_path='/usr/bin/chromedriver', log_path=None)
            # --- FIN DE CORRECCIÓN! ---

            self.driver = webdriver.Chrome(service=service, options=options)
            print("✅ Navegador Chrome (Chromium) iniciado (en modo silencioso)")
        except Exception as e:
            print(f"❌ Error al iniciar Chrome: {e}")
            raise

    def extract_brand(self, product_name):
            """Extraer marca del nombre del producto (versión mejorada)."""
            
            name_lower = product_name.lower()

            # --- Marcas Principales (CPU/GPU) ---
            if 'intel' in name_lower: return 'Intel'
            if 'amd' in name_lower or 'ryzen' in name_lower or 'radeon' in name_lower: return 'AMD'
            if 'nvidia' in name_lower or 'geforce' in name_lower or 'rtx' in name_lower or 'gtx' in name_lower: return 'NVIDIA'
            
            # --- Marcas de Fabricantes (Ensambladoras) ---
            if 'asus' in name_lower: return 'ASUS'
            if 'msi' in name_lower: return 'MSI'
            if 'gigabyte' in name_lower: return 'Gigabyte'
            if 'evga' in name_lower: return 'EVGA'
            if 'zotac' in name_lower: return 'Zotac'
            if 'sapphire' in name_lower: return 'Sapphire'
            if 'xfx' in name_lower: return 'XFX'
            if 'asrock' in name_lower: return 'ASRock'
            
            # --- Marcas de Otros Componentes ---
            if 'corsair' in name_lower: return 'Corsair'
            if 'kingston' in name_lower or 'fury' in name_lower: return 'Kingston'
            if 'samsung' in name_lower: return 'Samsung'
            if 'western digital' in name_lower or 'wd' in name_lower: return 'Western Digital'
            if 'seagate' in name_lower: return 'Seagate'
            if 'crucial' in name_lower: return 'Crucial'
            if 'noctua' in name_lower: return 'Noctua'
            if 'be quiet' in name_lower: return 'Be Quiet!'
            if 'nzxt' in name_lower: return 'NZXT'
            if 'thermaltake' in name_lower: return 'Thermaltake'
            if 'cooler master' in name_lower: return 'Cooler Master'
            if 'lian li' in name_lower: return 'Lian Li'
            
            # --- Marcas de Laptops ---
            if 'hp' in name_lower: return 'HP'
            if 'dell' in name_lower: return 'Dell'
            if 'lenovo' in name_lower: return 'Lenovo'
            if 'acer' in name_lower: return 'Acer'
            if 'razer' in name_lower: return 'Razer'
            
            if 'microsoft' in name_lower: return 'Microsoft'

            return "N/A" # Si no encuentra nada
    # (scrape_amazon - Copiado 1:1)
    def scrape_amazon(self, search_term, category_name, max_pages=7):
        """Scraper para Amazon México"""
        print(f"\n🔍 {category_name}: '{search_term}'")
        products = []
        
        try:
            for page in range(1, max_pages + 1):
                url = f"https://www.amazon.com.mx/s?k={urllib.parse.quote(search_term)}&page={page}"
                self.driver.get(url)
                
                try:
                    WebDriverWait(self.driver, 10).until(
                        EC.presence_of_element_located((By.CSS_SELECTOR, "[data-component-type='s-search-result']"))
                    )
                except:
                    time.sleep(5)
                
                self.driver.execute_script("window.scrollTo(0, document.body.scrollHeight/2);")
                time.sleep(1)
                self.driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
                time.sleep(2)
                
                results = self.driver.find_elements(By.CSS_SELECTOR, "[data-component-type='s-search-result']")
                print(f"   📄 Página {page}: {len(results)} resultados")
                
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
                                'patrocinado' not in line.lower()):
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
                        
                        # Imagen
                        image_url = None
                        try:
                            img = result.find_element(By.CSS_SELECTOR, "img.s-image")
                            image_url = img.get_attribute("src")
                        except:
                            pass
                        
                        if name and price and link:
                            brand = self.extract_brand(name)
                            products.append({
                                'category': category_name,
                                'name': name,
                                'brand': brand,
                                'price': price,
                                'image': image_url or "N/A",
                                'link': link,
                                'store': 'Amazon',
                                'page': page
                            })
                    
                    except Exception as e:
                        continue
                
                if page < max_pages:
                    time.sleep(3)
        
        except Exception as e:
            print(f"   ❌ Error: {e}")
        
        print(f"   ✅ {len(products)} productos extraídos")
        return products

    # (scrape_all_categories - MODIFICADO: sin input)
    def scrape_all_categories(self, max_pages=7):
        """Scraper TODAS las categorías"""
        print("\n" + "="*70)
        print("🛒 AMAZON PC COMPONENTS SCRAPER - MODO COMPLETO")
        print("="*70)
        print(f"⏰ Inicio: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"📦 Categorías: {len(self.components)}")
        print(f"📄 Páginas por búsqueda: {max_pages}")
        
        all_products = []
        category_stats = {}
        
        for category_name, config in self.components.items():
            print(f"\n{'='*70}")
            print(f"📦 CATEGORÍA: {category_name}")
            print(f"{'='*70}")
            
            category_products = []
            
            for keyword in config['keywords']:
                try:
                    products = self.scrape_amazon(keyword, category_name, max_pages)
                    category_products.extend(products)
                    time.sleep(3)
                except Exception as e:
                    print(f"   ⚠️  Error en keyword '{keyword}': {e}")
                    continue
            
            # Eliminar duplicados
            unique_products = self.remove_duplicates(category_products)
            
            # Filtrar productos
            filter_type = config.get('filter_type')
            print(f"\n🤖 Aplicando filtro para {category_name}...")
            filtered_products = self.filter_products(unique_products, filter_type)
            
            category_stats[category_name] = {
                'raw': len(category_products),
                'unique': len(unique_products),
                'filtered': len(filtered_products)
            }
            
            all_products.extend(filtered_products)
            print(f"✅ {category_name}: {len(filtered_products)} productos válidos\n")
        
        return all_products, category_stats

    # (remove_duplicates - Copiado 1:1)
    def remove_duplicates(self, products):
        """Eliminar duplicados"""
        if not products:
            return []
        
        unique = []
        seen = set()
        
        for product in products:
            name_key = re.sub(r'[^\w\s]', '', product['name'].lower())[:50]
            key = (name_key, product['price'])
            
            if key not in seen:
                seen.add(key)
                unique.append(product)
        
        return unique

    # (filter_products - Copiado 1:1)
    def filter_products(self, products, component_type):
        """Filtrar productos por tipo"""
        if not products:
            return []
        
        filtered = []
        rejected = []
        
        for product in products:
            name = product.get('name', '')
            is_valid, _, _ = self.component_filter.is_valid(name, component_type)
            
            if is_valid:
                filtered.append(product)
            else:
                rejected.append(product)
        
        if rejected:
            print(f"   🚫 Filtrados: {len(rejected)} productos no válidos")
        
        return filtered

    # --- MODIFICADO: 'save_results' ahora es 'save_results_to_db' ---
    def save_results_to_db(self, products: list, category_stats: dict):
        """
        Guardar resultados en la Base de Datos usando la lógica Upsert.
        """
        if not products:
            print("\n❌ No hay productos para guardar en la DB")
            return

        print(f"\n{'='*70}")
        print("💾 GUARDANDO EN BASE DE DATOS...")
        print(f"{'='*70}")
        print(f"📦 Total productos para procesar: {len(products)}")
        
        processed_count = 0

        for i, product in enumerate(products, 1):
            print(f"   Procesando {i}/{len(products)}: {product['name'][:50]}...")
            
            try:
                # --- Paso 1: Preparar Schemas (Pydantic) ---
                
                # El 'category_name' viene de la config, ej: "CPU"
                # El 'brand' lo extrajimos con 'extract_brand'
                component_in = ComponentCreate(
                    name=product['name'],
                    category=product['category'], 
                    brand=product['brand'],
                    image_url=product.get('image', None)
                )
                
                # Usamos Decimal para el precio para evitar errores de precisión
                offer_in = OfferCreate(
                    store=product['store'], # 'Amazon'
                    price=Decimal(product['price']),
                    link=product['link']
                )

                # --- Paso 2: Upsert Componente (Lógica de CRUD) ---
                # (Crea el componente si no existe, o lo recupera si ya existe)
                db_component = crud_scraper.upsert_component(self.db, component_in=component_in)
                
                if db_component is None:
                    print(f"   ⚠️  Error al hacer upsert del componente: {product['name']}")
                    continue
                
                # --- Paso 3: Upsert Oferta (Lógica de CRUD) ---
                # (Crea/actualiza la oferta para ESE componente y ESA tienda)
                crud_scraper.upsert_offer(self.db, component_id=db_component.id, offer_in=offer_in)
                
                processed_count += 1

            except Exception as e:
                print(f"   ❌ Error procesando '{product['name']}': {e}")
                self.db.rollback() # Revertir esta transacción específica
        
        print(f"\n✅ ¡Guardado en DB completado!")
        print(f"   {processed_count} ofertas actualizadas/creadas.")


    # --- MODIFICADO: 'run' ahora es no-interactivo ---
    def run(self, max_pages_per_search: int = 7):
        """
        Ejecutar scraper completo y guardar en DB.
        """
        try:
            print("\n🚀 Iniciando scraping completo de todas las categorías...")
            print(f"⏱️  Páginas por búsqueda: {max_pages_per_search}\n")
            
            # 1. Ejecutar scraping
            products, category_stats = self.scrape_all_categories(max_pages_per_search)
            
            # 2. Guardar resultados en la DB
            if products:
                self.save_results_to_db(products, category_stats)
                print(f"\n🎉 ¡Scraping completado exitosamente!")
                print(f"✅ {len(products)} productos totales encontrados y procesados.")
            else:
                print("\n⚠️  No se encontraron productos válidos")
        
        except KeyboardInterrupt:
            print("\n⏹️  Scraping interrumpido por el usuario")
        except Exception as e:
            print(f"\n❌ Error en 'run': {e}")
            import traceback
            traceback.print_exc()
        finally:
            self.cleanup()
    
    # (cleanup - Copiado 1:1)
    def cleanup(self):
        """Limpiar recursos"""
        try:
            if self.driver:
                self.driver.quit()
                print("\n🔒 Navegador cerrado")
        except:
            pass

# -------------------------------------------------------------------
# 3. BLOQUE DE EJECUCIÓN PRINCIPAL (NUEVO)
# -------------------------------------------------------------------
async def main():
    """
    Función principal asíncrona para ejecutar el scraper
    y la invalidación de caché.
    """
    print("Iniciando tarea de scraping...")
    
    # 1. Conectar a la DB
    db = SessionLocal()
    
    # 2. Conectar a Redis (para invalidación)
    await init_redis()
    
    scraper = None
    try:
        # 3. Iniciar el Scraper (pasándole la sesión de DB)
        scraper = MultiStoreScraper(db=db)
        
        # 4. Ejecutar (ej. 2 páginas por búsqueda)
        # (Este método NO es async, se ejecuta de forma síncrona)
        scraper.run(max_pages_per_search=7)
        
        # 5. Invalidar la caché de Redis
        print("\n" + "="*70)
        print("🔄 INVALIDANDO CACHÉ DE REDIS...")
        print("="*70)
        # Borramos las cachés de detalle y de listas
        await invalidate_cache("component_detail:*")
        await invalidate_cache("components:*")
        print("✅ Caché invalidada. La API servirá datos frescos.")

    except Exception as e:
        print(f"❌ Error fatal en el script principal: {e}")
        db.rollback()
    finally:
        if scraper:
            scraper.cleanup() # Cierra Selenium
        if db:
            db.close() # Cierra la sesión de DB
        await close_redis() # Cierra la conexión de Redis
        print("\nTarea de scraping finalizada.")


if __name__ == "__main__":
    # Como 'main' es una función async, la corremos con asyncio.run()
    asyncio.run(main())