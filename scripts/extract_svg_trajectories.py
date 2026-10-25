# scripts/extract_svg_trajectories.py
# Extraction et calibration des trajectoires vectorielles du rapport STATEC Analyses 02/26

import xml.etree.ElementTree as ET
import re
import csv
import json

def get_path_coords(filepath, path_idx):
    tree = ET.parse(filepath)
    root = tree.getroot()
    paths = root.findall(".//{http://www.w3.org/2000/svg}path")
    p = paths[path_idx]
    d = p.get("d", "")
    cmds = re.findall(r"([MLC])\s*([-\d.]+)\s+([-\d.]+)", d)
    return [(float(c[1]), float(c[2])) for c in cmds]

# 1. Extraction Population (Page 30, indices 1807 historique, 1808-1811 scénarios)
# Années: 1807 = 2000 à 2029 (30 ans), 1808-1811 = 2029 à 2070 (42 points)
coords_hist_pop = get_path_coords("data/page30.svg", 1807)
coords_sc1_pop = get_path_coords("data/page30.svg", 1808)
coords_sc2_pop = get_path_coords("data/page30.svg", 1809)
coords_sc3_pop = get_path_coords("data/page30.svg", 1810)
coords_sc4_pop = get_path_coords("data/page30.svg", 1811)

# Échelle verticale:
# Y_2025 (point 25 dans 1807) = 691 000
# Y_2070 Scénario 1 = 944 039 (y = 26.665764)
# Y_2070 Scénario 4 = 1 066 516 (y = 42.204171)
# dy = 42.204171 - 26.665764 = 15.538407 -> dPop = 122 477 -> scale = 7882.21
scale_pop = (1066516 - 944039) / (coords_sc4_pop[-1][1] - coords_sc1_pop[-1][1])
y_base_pop = coords_sc1_pop[-1][1] - 944039 / scale_pop

print(f"Population scale: {scale_pop:.2f}, base: {y_base_pop:.2f}")

population_data = []

# Historique / moyen terme 2000-2029
for idx, (x, y) in enumerate(coords_hist_pop):
    yr = 2000 + idx
    val = round((y - y_base_pop) * scale_pop)
    population_data.append({
        "year": yr,
        "scenario_id": "OBS_MT",
        "scenario_name": "Observé / Moyen terme (STATEC)",
        "indicator": "population",
        "value": val,
        "data_type": "observed" if yr <= 2025 else "medium_term_projection"
    })

# Scénarios 2029-2070
scenarios_pop = [
    ("SC1", "Scénario 1 : Faible productivité", coords_sc1_pop, 944039),
    ("SC2", "Scénario 2 : Investissement intensif", coords_sc2_pop, 966018),
    ("SC3", "Scénario 3 : Innovation importée", coords_sc3_pop, 1022428),
    ("SC4", "Scénario 4 : Forte productivité", coords_sc4_pop, 1066516),
]

for sc_id, sc_name, coords, target_2070 in scenarios_pop:
    for idx, (x, y) in enumerate(coords):
        yr = 2029 + idx
        raw_val = (y - y_base_pop) * scale_pop
        # ajustement linéaire pour garantir la valeur exacte en 2070
        weight = idx / (len(coords) - 1)
        err_2070 = target_2070 - ((coords[-1][1] - y_base_pop) * scale_pop)
        calibrated_val = round(raw_val + weight * err_2070)
        population_data.append({
            "year": yr,
            "scenario_id": sc_id,
            "scenario_name": sc_name,
            "indicator": "population",
            "value": calibrated_val,
            "data_type": "projected"
        })

# 2. Extraction Solde migratoire (Page 29, indices 3061 historique, 3062-3065 scénarios)
coords_hist_mig = get_path_coords("data/page_29.svg", 3061)
coords_sc1_mig = get_path_coords("data/page_29.svg", 3062)
coords_sc2_mig = get_path_coords("data/page_29.svg", 3063)
coords_sc3_mig = get_path_coords("data/page_29.svg", 3064)
coords_sc4_mig = get_path_coords("data/page_29.svg", 3065)

# En 2070: Sc1 = 3284 (y = -32.368), Sc4 = 7454 (y = -11.370)
# dy = -11.370 - (-32.368) = 20.998 -> dMig = 4170 -> scale = 198.59
scale_mig = (7454 - 3284) / (coords_sc4_mig[-1][1] - coords_sc1_mig[-1][1])
y_base_mig = coords_sc1_mig[-1][1] - 3284 / scale_mig

print(f"Migration scale: {scale_mig:.2f}, base: {y_base_mig:.2f}")

migration_data = []

for idx, (x, y) in enumerate(coords_hist_mig):
    yr = 2000 + idx
    val = round((y - y_base_mig) * scale_mig)
    migration_data.append({
        "year": yr,
        "scenario_id": "OBS_MT",
        "scenario_name": "Observé / Moyen terme (STATEC)",
        "indicator": "solde_migratoire",
        "value": val,
        "data_type": "observed" if yr <= 2025 else "medium_term_projection"
    })

scenarios_mig = [
    ("SC1", "Scénario 1 : Faible productivité", coords_sc1_mig, 3284),
    ("SC2", "Scénario 2 : Investissement intensif", coords_sc2_mig, 3692),
    ("SC3", "Scénario 3 : Innovation importée", coords_sc3_mig, 6084),
    ("SC4", "Scénario 4 : Forte productivité", coords_sc4_mig, 7454),
]

for sc_id, sc_name, coords, target_2070 in scenarios_mig:
    for idx, (x, y) in enumerate(coords):
        yr = 2029 + idx
        raw_val = (y - y_base_mig) * scale_mig
        weight = idx / (len(coords) - 1)
        err_2070 = target_2070 - ((coords[-1][1] - y_base_mig) * scale_mig)
        calibrated_val = round(raw_val + weight * err_2070)
        migration_data.append({
            "year": yr,
            "scenario_id": sc_id,
            "scenario_name": sc_name,
            "indicator": "solde_migratoire",
            "value": calibrated_val,
            "data_type": "projected"
        })

# 3. Extraction Emploi total (Page 39, indices 2147 historique, 2148-2151 scénarios)
coords_hist_emp = get_path_coords("data/page_39.svg", 2147)
coords_sc1_emp = get_path_coords("data/page_39.svg", 2148)
coords_sc2_emp = get_path_coords("data/page_39.svg", 2149)
coords_sc3_emp = get_path_coords("data/page_39.svg", 2150)
coords_sc4_emp = get_path_coords("data/page_39.svg", 2151)

# En 2070 (Tableau 4):
# Sc1 Emploi total = 338 074 + 397 407 = 735 481 (y = 3.916)
# Sc4 Emploi total = 401 296 + 525 466 = 926 762 (y = 40.057)
# dy = 36.141 -> dEmp = 191 281 -> scale = 5292.5
scale_emp = (926762 - 735481) / (coords_sc4_emp[-1][1] - coords_sc1_emp[-1][1])
y_base_emp = coords_sc1_emp[-1][1] - 735481 / scale_emp

employment_data = []

scenarios_emp = [
    ("SC1", "Scénario 1 : Faible productivité", coords_sc1_emp, 735481),
    ("SC2", "Scénario 2 : Investissement intensif", coords_sc2_emp, 770790),
    ("SC3", "Scénario 3 : Innovation importée", coords_sc3_emp, 855205),
    ("SC4", "Scénario 4 : Forte productivité", coords_sc4_emp, 926762),
]

for sc_id, sc_name, coords, target_2070 in scenarios_emp:
    for idx, (x, y) in enumerate(coords):
        yr = 2029 + idx
        raw_val = (y - y_base_emp) * scale_emp
        weight = idx / (len(coords) - 1)
        err_2070 = target_2070 - ((coords[-1][1] - y_base_emp) * scale_emp)
        calibrated_val = round(raw_val + weight * err_2070)
        employment_data.append({
            "year": yr,
            "scenario_id": sc_id,
            "scenario_name": sc_name,
            "indicator": "emploi_total",
            "value": calibrated_val,
            "data_type": "projected"
        })

# Sauvegarde des trajectoires complètes
all_trajectories = population_data + migration_data + employment_data
with open("data/statec_extracted_trajectories.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["year", "scenario_id", "scenario_name", "indicator", "value", "data_type"])
    writer.writeheader()
    writer.writerows(all_trajectories)

print(f"Total extracted trajectory points: {len(all_trajectories)}")
