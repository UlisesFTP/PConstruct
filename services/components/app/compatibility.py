from . import schemas
from typing import List

# Reglas de compatibilidad predefinidas
COMPATIBILITY_RULES = [
    {
        "rule_id": "socket-match",
        "description": "El socket del CPU debe coincidir con el de la motherboard",
        "applies_to": ["CPU", "Motherboard"],
        "condition": {
            "required": ["CPU", "Motherboard"],
            "check": "cpu.specs['socket'] == motherboard.specs['socket']",
            "error": "El socket del CPU ({cpu_socket}) no coincide con la motherboard ({mobo_socket})"
        }
    },
    {
        "rule_id": "ram-compatibility",
        "description": "La RAM debe ser compatible con la motherboard",
        "applies_to": ["RAM", "Motherboard"],
        "condition": {
            "required": ["RAM", "Motherboard"],
            "check": "ram.specs['type'] in motherboard.specs['supported_ram']",
            "error": "Tipo de RAM {ram_type} no soportado por la motherboard"
        }
    },
    {
        "rule_id": "psu-wattage",
        "description": "La fuente de poder debe tener suficiente potencia",
        "applies_to": ["Power Supply"],
        "condition": {
            "required": ["Power Supply"],
            "check": "psu.specs['wattage'] >= total_power_estimate",
            "dynamic": True  # Requiere cálculo dinámico
        }
    }
]

def check_compatibility(components: List) -> schemas.CompatibilityResult:
    issues = []
    compatible = True
    
    # Organizar componentes por categoría
    components_by_category = {}
    for comp in components:
        components_by_category.setdefault(comp.category, []).append(comp)
    
    # Verificar cada regla
    for rule in COMPATIBILITY_RULES:
        # Verificar si tenemos los componentes necesarios para esta regla
        required_categories = rule["condition"].get("required", [])
        if not all(cat in components_by_category for cat in required_categories):
            continue
        
        # Aplicar la regla
        rule_result = _apply_rule(rule, components_by_category)
        if rule_result:
            issues.extend(rule_result)
            compatible = False
    
    return schemas.CompatibilityResult(compatible=compatible, issues=issues)

def _apply_rule(rule: dict, components_by_category: dict) -> list:
    issues = []
    condition = rule["condition"]
    
    if rule["rule_id"] == "socket-match":
        cpu = components_by_category["CPU"][0]
        mobo = components_by_category["Motherboard"][0]
        
        if cpu.specs.get("socket") != mobo.specs.get("socket"):
            issues.append(schemas.CompatibilityIssue(
                component_id=cpu.id,
                issue=f"Socket del CPU ({cpu.specs['socket']}) no coincide con la motherboard ({mobo.specs['socket']})",
                severity="error"
            ))
    
    elif rule["rule_id"] == "ram-compatibility":
        ram_modules = components_by_category["RAM"]
        mobo = components_by_category["Motherboard"][0]
        supported_types = mobo.specs.get("supported_ram", [])
        
        for ram in ram_modules:
            ram_type = ram.specs.get("type")
            if ram_type not in supported_types:
                issues.append(schemas.CompatibilityIssue(
                    component_id=ram.id,
                    issue=f"Tipo de RAM {ram_type} no soportado por la motherboard",
                    severity="error"
                ))
    
    elif rule["rule_id"] == "psu-wattage":
        psu = components_by_category["Power Supply"][0]
        total_power = _calculate_total_power(components_by_category)
        
        if psu.specs.get("wattage", 0) < total_power:
            issues.append(schemas.CompatibilityIssue(
                component_id=psu.id,
                issue=f"La fuente de poder ({psu.specs['wattage']}W) es insuficiente para el sistema estimado ({total_power}W)",
                severity="error"
            ))
    
    return issues

def _calculate_total_power(components_by_category: dict) -> int:
    """Calcula el consumo total estimado de energía"""
    power_estimates = {
        "CPU": 150,
        "GPU": 250,
        "Motherboard": 50,
        "RAM": 10,
        "Storage": 20,
        "Cooler": 10,
        "Other": 50
    }
    
    total = 0
    for category, components in components_by_category.items():
        category_key = category if category in power_estimates else "Other"
        total += len(components) * power_estimates[category_key]
    
    # Añadir margen de seguridad
    return int(total * 1.2)

def get_all_rules():
    return [schemas.CompatibilityRule(**rule) for rule in COMPATIBILITY_RULES]