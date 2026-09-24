#!/usr/bin/env python3
"""
Erzeugt Beispieldaten für die beiden PostgreSQL-Quellsysteme.

Die Daten passen zu init_quellsysteme.sql (Schema ohne Beispieldaten).

Ausgabe:
    beispieldaten.sql

Die SQL-Datei wird im gleichen Verzeichnis erzeugt, in dem dieses Skript
ausgeführt wird.

Hinweis:
- Die vorhandenen Tabellen werden in der SQL-Datei zuerst geleert.
- Anschließend werden alle Beispieldaten per INSERT eingefügt.
- Ohne Parameter wird der feste Seed 12345 verwendet. Der Lauf ist damit
  reproduzierbar. Ein anderer Seed kann angegeben werden:
      python generate_data.py 4711
"""

from __future__ import annotations

import random
import sys
from datetime import date, timedelta
from decimal import Decimal
from pathlib import Path


# ------------------------------------------------------------
# Konfiguration
# ------------------------------------------------------------

OUTPUT_FILE = Path.cwd() / "beispieldaten.sql"

START_DATE = date(2024, 1, 1)
END_DATE = date(2025, 12, 31)

DEFAULT_SEED = 12345

SEED = DEFAULT_SEED
if len(sys.argv) > 1:
    try:
        SEED = int(sys.argv[1])
    except ValueError:
        raise SystemExit("Der Seed muss eine Ganzzahl sein, z. B. 12345.")
random.seed(SEED)

# Bewusste Muster, damit die Auswertungen etwas zeigen.
# Ein Faktor von 1.0 bedeutet kein Effekt.
BASE_VIOLATION_RATE = 0.12          # Anteil Bearbeitungsvorgänge über der SLA-Zielzeit
MANUFACTURER_VIOLATION_FACTOR = {   # Hersteller mit mehr SLA-Überschreitungen
    "Sophos": 2.5,
    "Lenovo": 1.8,
}
SLOW_LOCATION_ID = 3                # Standort mit mehr SLA-Überschreitungen
SLOW_LOCATION_FACTOR = 2.0
MAX_VIOLATION_RATE = 0.60

# Relative Häufigkeit von Tickets je Gerätetyp (Core-Switches selten)
TICKET_WEIGHT_BY_DEVICE_TYPE = {
    "Firewall": 1.2,
    "Core-Switch": 0.3,
    "Access Point": 1.0,
    "Server": 1.8,
}

# Kostenfaktor der Wartungsverträge je Gerätetyp (Core-Switches teuer)
CONTRACT_COST_FACTOR = {
    "Firewall": 1.0,
    "Core-Switch": 1.6,
    "Access Point": 0.7,
    "Server": 1.2,
}


# ------------------------------------------------------------
# Hilfsfunktionen
# ------------------------------------------------------------

def sql_string(value: str) -> str:
    """Escaped einen String für PostgreSQL."""
    return "'" + value.replace("'", "''") + "'"


def sql_date(value: date) -> str:
    return f"'{value.isoformat()}'"


def sql_decimal(value: float | Decimal) -> str:
    return f"{Decimal(str(value)):.2f}"


def random_date(start: date, end: date) -> date:
    days = (end - start).days
    return start + timedelta(days=random.randint(0, days))


def weighted_choice(values, weights):
    return random.choices(values, weights=weights, k=1)[0]


def insert_statement(schema, table, columns, rows):
    """Erzeugt ein PostgreSQL-INSERT mit mehreren VALUES-Zeilen."""
    if not rows:
        return ""

    col_sql = ", ".join(columns)
    value_sql = ",\n".join(
        "(" + ", ".join(row) + ")" for row in rows
    )

    return (
        f'INSERT INTO {schema}.{table} ({col_sql}) VALUES\n'
        f'{value_sql};\n'
    )


# ------------------------------------------------------------
# Stammdaten
# ------------------------------------------------------------

FIRST_NAMES = [
    "Anna", "Ben", "Clara", "Daniel", "Elena", "Felix", "Hannah",
    "Jan", "Julia", "Laura", "Leon", "Lisa", "Lukas", "Marie",
    "Markus", "Max", "Nina", "Paul", "Sarah", "Sophie", "Tim",
    "Tobias", "Christian", "David"
]

LAST_NAMES = [
    "Bauer", "Becker", "Fischer", "Hoffmann", "Keller", "Koch",
    "Lang", "Lehmann", "Meier", "Müller", "Neumann", "Richter",
    "Schmidt", "Schneider", "Scholz", "Schubert", "Schulz",
    "Wagner", "Weber", "Wolf", "Zimmermann"
]

CITIES = [
    ("Dresden", "Sachsen", "Deutschland"),
    ("Leipzig", "Sachsen", "Deutschland"),
    ("Chemnitz", "Sachsen", "Deutschland"),
    ("Berlin", "Berlin", "Deutschland"),
    ("Potsdam", "Brandenburg", "Deutschland"),
    ("München", "Bayern", "Deutschland"),
    ("Nürnberg", "Bayern", "Deutschland"),
    ("Frankfurt", "Hessen", "Deutschland"),
    ("Wiesbaden", "Hessen", "Deutschland"),
    ("Hamburg", "Hamburg", "Deutschland"),
    ("Köln", "Nordrhein-Westfalen", "Deutschland"),
    ("Stuttgart", "Baden-Württemberg", "Deutschland"),
    ("Hannover", "Niedersachsen", "Deutschland"),
    ("Bremen", "Bremen", "Deutschland"),
    ("Wien", "Wien", "Österreich"),
]

LOCATION_PREFIXES = [
    "Hauptsitz",
    "Niederlassung",
    "Campus",
    "Standort",
    "Datacenter",
    "Servicezentrum",
    "Logistikzentrum",
]

CUSTOMER_PREFIXES = [
    "Müller", "Schneider", "Bauer", "Kronberg", "Elbe",
    "Rhein", "Hanse", "Sachsen", "Bavaria", "Capital",
    "Nord", "Central", "Alpen", "West", "Metro"
]

CUSTOMER_SUFFIXES = [
    "GmbH", "AG", "GmbH & Co. KG", "SE", "Solutions GmbH",
    "Industrie GmbH", "Systems AG", "Logistik GmbH"
]

CUSTOMER_TYPES = ["Kleinunternehmen", "Mittelstand", "Konzern"]

# Gerätetyp -> Hersteller -> Modelle. Die Modelle passen zum Gerätetyp.
DEVICE_CATALOG = {
    "Firewall": {
        "Fortinet": ["FortiGate 60F", "FortiGate 100F", "FortiGate 200F"],
        "Sophos": ["XGS 107", "XGS 136", "XGS 2100"],
        "Cisco": ["Firepower 1010", "Firepower 1120", "Firepower 2110"],
    },
    "Core-Switch": {
        "Cisco": ["Catalyst 9200", "Catalyst 9300", "Catalyst 9500"],
        "Aruba": ["CX 6300", "CX 6400", "CX 8320"],
    },
    "Access Point": {
        "Cisco": ["Catalyst 9115AX", "Catalyst 9120AX", "Catalyst 9130AX"],
        "Aruba": ["AP-515", "AP-535", "AP-635"],
        "LANCOM": ["LX-6400", "LX-6500", "LW-600"],
    },
    "Server": {
        "Dell": ["PowerEdge R550", "PowerEdge R650", "PowerEdge R750"],
        "HPE": ["ProLiant DL360", "ProLiant DL380", "ProLiant ML350"],
        "Lenovo": ["ThinkSystem SR250", "ThinkSystem SR630", "ThinkSystem SR650"],
    },
}

DEVICE_TYPE_WEIGHTS = {
    "Firewall": 25,
    "Core-Switch": 20,
    "Access Point": 35,
    "Server": 20,
}

CONTRACT_TYPES = [
    ("24/7 Premium", 800, 1500),
    ("8x5 Standard", 400, 800),
    ("Next-Business-Day", 200, 500),
]

MAINTENANCE_COSTS = {
    "Firmware-Update": (0, 100),
    "Komponententausch": (200, 800),
    "Konfigurationsprüfung": (50, 150),
    "Inspektion": (50, 150),
}
MAINTENANCE_TYPES = list(MAINTENANCE_COSTS)

TICKET_CATEGORIES = ["Hardware", "Netzwerk", "Security", "Software"]

# Priorität -> SLA-Zielzeit in Minuten (Rangfolge: Kritisch, Hoch, Normal)
TICKET_PRIORITIES = {
    "Kritisch": 120,
    "Hoch": 240,
    "Normal": 480,
}

TICKET_ACTIONS = [
    "Diagnose",
    "Konfiguration",
    "Patch",
    "Komponententausch",
    "Sicherheitsprüfung",
    "Abschlusstest",
]

TEAMS = [
    "Helpdesk",
    "Netzwerktechnik",
    "Field Service",
]

ROLES = {
    "Helpdesk": ["Supportmitarbeiter", "Senior Supportmitarbeiter"],
    "Netzwerktechnik": ["Techniker", "Senior Techniker", "Netzwerkingenieur"],
    "Field Service": ["Techniker", "Field Service Engineer"],
}


# ------------------------------------------------------------
# Daten erzeugen
# ------------------------------------------------------------

def create_name(used_names):
    while True:
        name = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
        if name not in used_names:
            used_names.add(name)
            return name


def generate_locations():
    count = random.randint(10, 15)
    selected = random.sample(CITIES, count)

    locations = []
    for location_id, (city, region, country) in enumerate(selected, start=1):
        locations.append({
            "StandortID": location_id,
            "Standortbezeichnung": f"{random.choice(LOCATION_PREFIXES)} {city}",
            "Region": region,
            "Land": country,
        })

    return locations


def generate_employees():
    count = random.randint(10, 15)
    employees = []
    used_names = set()

    # Jedes Team ist mindestens einmal vertreten.
    teams = TEAMS + [random.choice(TEAMS) for _ in range(count - len(TEAMS))]
    random.shuffle(teams)

    for employee_id, team in zip(range(401, 401 + count), teams):
        employees.append({
            "MitarbeiterNr": employee_id,
            "Name": create_name(used_names),
            "Team": team,
            "Rolle": random.choice(ROLES[team]),
        })

    return employees


def generate_customers():
    count = random.randint(8, 12)
    customers = []
    used_names = set()

    for customer_id in range(201, 201 + count):
        while True:
            name = (
                f"{random.choice(CUSTOMER_PREFIXES)} "
                f"{random.choice(CUSTOMER_SUFFIXES)}"
            )
            if name not in used_names:
                used_names.add(name)
                break

        customers.append({
            "KundenNr": customer_id,
            "Kunden_Name": name,
            "Kundentyp": weighted_choice(CUSTOMER_TYPES, [25, 55, 20]),
        })

    return customers


def generate_account_managers(customers):
    managers = []
    used_names = set()

    for i, customer in enumerate(customers):
        managers.append({
            "BetreuerNr": 301 + i,
            "KundenNr": customer["KundenNr"],
            "Name": create_name(used_names),
            "Team": random.choice([
                "Key Accounts",
                "Regionalbetreuung",
                "Kundenservice",
            ]),
        })

    return managers


def generate_devices(locations, customers):
    count = random.randint(60, 100)
    devices = []

    # Die ersten Geräte decken alle Standorte und alle Kunden ab.
    # Danach werden Standort und Kunde zufällig gewählt.
    location_order = [
        location["StandortID"]
        for location in random.sample(locations, len(locations))
    ]
    customer_order = [
        customer["KundenNr"]
        for customer in random.sample(customers, len(customers))
    ]

    for index, device_id in enumerate(range(101, 101 + count)):
        device_type = weighted_choice(
            list(DEVICE_TYPE_WEIGHTS),
            list(DEVICE_TYPE_WEIGHTS.values())
        )
        manufacturer = random.choice(list(DEVICE_CATALOG[device_type]))
        model = random.choice(DEVICE_CATALOG[device_type][manufacturer])

        if index < len(location_order):
            location_id = location_order[index]
        else:
            location_id = random.choice(locations)["StandortID"]

        if index < len(customer_order):
            customer_id = customer_order[index]
        else:
            customer_id = random.choice(customers)["KundenNr"]

        devices.append({
            "GeräteNr": device_id,
            "Gerätetyp": device_type,
            "Hersteller": manufacturer,
            "Modell": model,
            "StandortID": location_id,
            # Anschaffung vor Beginn des Betrachtungszeitraums.
            "Anschaffungsdatum": random_date(
                date(2019, 1, 1),
                date(2023, 12, 31)
            ),
            "KundenNr": customer_id,
        })

    return devices


def generate_contracts(devices):
    """Wartungsverträge werden jahresweise angelegt (1.1. bis 31.12.).

    Die meisten Geräte haben in beiden Jahren einen Vertrag. Bei einem Teil
    wechselt die Vertragsart. Einige Geräte haben nur in einem Jahr oder gar
    keinen Vertrag.
    """
    contracts = []
    contract_id = 5001

    first_year = START_DATE.year
    last_year = END_DATE.year

    patterns = {
        "beide Jahre": [first_year, last_year],
        "nur erstes Jahr": [first_year],
        "nur letztes Jahr": [last_year],
        "kein Vertrag": [],
    }

    for device in devices:
        pattern = weighted_choice(list(patterns), [80, 8, 8, 4])
        previous_type = None

        for year in patterns[pattern]:
            if previous_type is None:
                contract_type = random.choice(CONTRACT_TYPES)
            elif random.random() < 0.75:
                contract_type = previous_type
            else:
                contract_type = random.choice(
                    [c for c in CONTRACT_TYPES if c != previous_type]
                )

            name, min_cost, max_cost = contract_type
            factor = CONTRACT_COST_FACTOR[device["Gerätetyp"]]

            contracts.append({
                "VertragsNr": contract_id,
                "GeräteNr": device["GeräteNr"],
                "Vertragsart": name,
                "Beginn": date(year, 1, 1),
                "Ende": date(year, 12, 31),
                "Kosten_pro_Jahr": round(
                    random.uniform(min_cost, max_cost) * factor, 2
                ),
            })

            contract_id += 1
            previous_type = contract_type

    return contracts


def generate_maintenance(contracts):
    """Wartungen finden nur innerhalb eines gültigen Vertrags statt."""
    maintenance = []

    for contract in contracts:
        for _ in range(random.randint(1, 2)):
            maintenance_type = random.choice(MAINTENANCE_TYPES)
            min_cost, max_cost = MAINTENANCE_COSTS[maintenance_type]

            maintenance.append({
                "GeräteNr": contract["GeräteNr"],
                "Datum": random_date(contract["Beginn"], contract["Ende"]),
                "Wartungsart": maintenance_type,
                "Kosten": round(random.uniform(min_cost, max_cost), 2),
            })

    maintenance.sort(key=lambda m: (m["Datum"], m["GeräteNr"]))
    for maintenance_id, row in enumerate(maintenance, start=9001):
        row["WartungsNr"] = maintenance_id

    return maintenance


def generate_tickets(customers, devices):
    count = random.randint(300, 600)
    tickets = []

    # Ein Ticket bezieht sich auf ein Gerät des jeweiligen Kunden.
    devices_by_customer = {}
    for device in devices:
        devices_by_customer.setdefault(device["KundenNr"], []).append(device)

    for _ in range(count):
        customer = random.choice(customers)
        available_devices = devices_by_customer[customer["KundenNr"]]

        device = random.choices(
            available_devices,
            weights=[
                TICKET_WEIGHT_BY_DEVICE_TYPE[d["Gerätetyp"]]
                for d in available_devices
            ],
            k=1
        )[0]

        priority = weighted_choice(
            list(TICKET_PRIORITIES),
            [10, 25, 65]
        )

        created = random_date(START_DATE, END_DATE)

        # Offen sind nur Tickets aus den letzten Wochen.
        if created >= END_DATE - timedelta(days=30):
            status = weighted_choice(
                ["Geschlossen", "Gelöst", "In Bearbeitung"],
                [40, 20, 40]
            )
        else:
            status = weighted_choice(["Geschlossen", "Gelöst"], [70, 30])

        tickets.append({
            "KundenNr": customer["KundenNr"],
            "GeräteNr": device["GeräteNr"],
            "Erstellungsdatum": created,
            "Kategorie": weighted_choice(
                TICKET_CATEGORIES,
                [25, 40, 20, 15]
            ),
            "Priorität": priority,
            "Status": status,
            "SLA_Zielzeit_Minuten": TICKET_PRIORITIES[priority],
        })

    tickets.sort(key=lambda t: (t["Erstellungsdatum"], t["KundenNr"]))
    for ticket_id, row in enumerate(tickets, start=1001):
        row["TicketNr"] = ticket_id

    return tickets


def violation_probability(device):
    """Wahrscheinlichkeit, dass ein Bearbeitungsvorgang die SLA überschreitet."""
    probability = BASE_VIOLATION_RATE
    probability *= MANUFACTURER_VIOLATION_FACTOR.get(device["Hersteller"], 1.0)

    if device["StandortID"] == SLOW_LOCATION_ID:
        probability *= SLOW_LOCATION_FACTOR

    return min(probability, MAX_VIOLATION_RATE)


def generate_processings(tickets, employees, devices):
    """Erzeugt die Bearbeitungsvorgänge.

    Die SLA-Konformität wird je Bearbeitungsvorgang bewertet. Ein Vorgang
    ist konform, wenn Bearbeitungszeit_Minuten <= SLA_Zielzeit_Minuten.
    """
    processings = []
    processing_id = 8001

    device_by_id = {device["GeräteNr"]: device for device in devices}
    employee_ids = [employee["MitarbeiterNr"] for employee in employees]

    for ticket in tickets:
        device = device_by_id[ticket["GeräteNr"]]
        probability = violation_probability(device)
        sla = ticket["SLA_Zielzeit_Minuten"]

        current_day = ticket["Erstellungsdatum"]

        # 1 bis 4 Bearbeitungsschritte pro Ticket.
        for _ in range(weighted_choice([1, 2, 3, 4], [35, 30, 20, 15])):
            # Bearbeitung am Erstellungstag oder danach, nie nach Ende
            # des Betrachtungszeitraums.
            current_day = min(
                END_DATE,
                current_day + timedelta(days=random.choice([0, 0, 1, 1, 2, 3]))
            )

            if random.random() < probability:
                minutes = int(sla * random.uniform(1.05, 1.80))
            else:
                minutes = int(sla * random.uniform(0.10, 0.85))

            processings.append({
                "BearbeitungsNr": processing_id,
                "TicketNr": ticket["TicketNr"],
                "MitarbeiterNr": random.choice(employee_ids),
                "Datum": current_day,
                "Bearbeitungszeit_Minuten": max(10, minutes),
                "Aktionstyp": random.choice(TICKET_ACTIONS),
            })

            processing_id += 1

    return processings


def check_consistency(locations, customers, devices, contracts,
                      maintenance, tickets, processings, employees):
    """Prüft die Randbedingungen der Beispieldaten."""
    device_by_id = {d["GeräteNr"]: d for d in devices}
    ticket_by_id = {t["TicketNr"]: t for t in tickets}
    location_ids = {loc["StandortID"] for loc in locations}
    customer_ids = {c["KundenNr"] for c in customers}
    employee_ids = {e["MitarbeiterNr"] for e in employees}

    assert SLOW_LOCATION_ID in location_ids, "SLOW_LOCATION_ID existiert nicht"
    assert {d["StandortID"] for d in devices} == location_ids, \
        "Nicht jeder Standort hat Geräte"
    assert {d["KundenNr"] for d in devices} == customer_ids, \
        "Nicht jeder Kunde hat Geräte"
    assert {e["Team"] for e in employees} == set(TEAMS), \
        "Nicht jedes Team hat Mitarbeiter"

    # Verträge: gültige Laufzeit, keine Überlappung je Gerät
    by_device = {}
    for c in contracts:
        assert c["Beginn"] <= c["Ende"]
        assert START_DATE <= c["Beginn"] and c["Ende"] <= END_DATE
        by_device.setdefault(c["GeräteNr"], []).append(c)
    for rows in by_device.values():
        rows.sort(key=lambda c: c["Beginn"])
        for a, b in zip(rows, rows[1:]):
            assert a["Ende"] < b["Beginn"], "Überlappende Verträge"

    # Wartungen liegen innerhalb eines gültigen Vertrags
    for m in maintenance:
        assert any(
            c["Beginn"] <= m["Datum"] <= c["Ende"]
            for c in by_device.get(m["GeräteNr"], [])
        ), "Wartung ohne gültigen Vertrag"

    # Tickets: Gerät gehört zum Kunden, Datum im Zeitraum
    for t in tickets:
        device = device_by_id[t["GeräteNr"]]
        assert t["KundenNr"] in customer_ids
        assert device["KundenNr"] == t["KundenNr"], "Gerät gehört nicht zum Kunden"
        assert START_DATE <= t["Erstellungsdatum"] <= END_DATE
        assert t["Erstellungsdatum"] >= device["Anschaffungsdatum"]
        assert t["SLA_Zielzeit_Minuten"] == TICKET_PRIORITIES[t["Priorität"]]

    # Bearbeitungen: nicht vor der Ticketerstellung, im Zeitraum
    for p in processings:
        ticket = ticket_by_id[p["TicketNr"]]
        assert p["MitarbeiterNr"] in employee_ids
        assert ticket["Erstellungsdatum"] <= p["Datum"] <= END_DATE, \
            "Bearbeitung vor Ticketerstellung"
        assert p["Bearbeitungszeit_Minuten"] > 0


# ------------------------------------------------------------
# SQL-Erzeugung
# ------------------------------------------------------------

def generate_sql():
    locations = generate_locations()
    employees = generate_employees()
    customers = generate_customers()
    account_managers = generate_account_managers(customers)
    devices = generate_devices(locations, customers)
    contracts = generate_contracts(devices)
    maintenance = generate_maintenance(contracts)
    tickets = generate_tickets(customers, devices)
    processings = generate_processings(tickets, employees, devices)

    check_consistency(
        locations, customers, devices, contracts,
        maintenance, tickets, processings, employees
    )

    lines = []

    lines.append("-- =========================================================")
    lines.append("-- Automatisch erzeugte Beispieldaten")
    lines.append("-- PostgreSQL, passend zu init_quellsysteme.sql")
    lines.append(f"-- Seed: {SEED}")
    lines.append("-- =========================================================")
    lines.append("")
    lines.append("BEGIN;")
    lines.append("")

    # Tabellen leeren. CASCADE berücksichtigt auch vorhandene
    # Fremdschlüsselabhängigkeiten.
    lines.append("-- Vorhandene Daten entfernen")
    lines.append(
        "TRUNCATE TABLE "
        "src_ticketsystem.Bearbeitung, "
        "src_ticketsystem.Ticket, "
        "src_ticketsystem.Kundenbetreuer, "
        "src_ticketsystem.Mitarbeiter, "
        "src_ticketsystem.Kunde, "
        "src_inventarsystem.Wartung, "
        "src_inventarsystem.Wartungsvertrag, "
        "src_inventarsystem.Gerät, "
        "src_inventarsystem.Standort "
        "RESTART IDENTITY CASCADE;"
    )
    lines.append("")

    # Standort
    rows = [
        [
            str(row["StandortID"]),
            sql_string(row["Standortbezeichnung"]),
            sql_string(row["Region"]),
            sql_string(row["Land"]),
        ]
        for row in locations
    ]

    lines.append("-- Standorte")
    lines.append(
        insert_statement(
            "src_inventarsystem",
            "Standort",
            [
                "StandortID",
                "Standortbezeichnung",
                "Region",
                "Land",
            ],
            rows,
        )
    )

    # Geräte
    rows = [
        [
            str(row["GeräteNr"]),
            sql_string(row["Gerätetyp"]),
            sql_string(row["Hersteller"]),
            sql_string(row["Modell"]),
            str(row["StandortID"]),
            sql_date(row["Anschaffungsdatum"]),
            str(row["KundenNr"]),
        ]
        for row in devices
    ]

    lines.append("-- Geräte")
    lines.append(
        insert_statement(
            "src_inventarsystem",
            "Gerät",
            [
                "GeräteNr",
                "Gerätetyp",
                "Hersteller",
                "Modell",
                "StandortID",
                "Anschaffungsdatum",
                "KundenNr",
            ],
            rows,
        )
    )

    # Wartungsverträge
    rows = [
        [
            str(row["VertragsNr"]),
            str(row["GeräteNr"]),
            sql_string(row["Vertragsart"]),
            sql_date(row["Beginn"]),
            sql_date(row["Ende"]),
            sql_decimal(row["Kosten_pro_Jahr"]),
        ]
        for row in contracts
    ]

    lines.append("-- Wartungsverträge")
    lines.append(
        insert_statement(
            "src_inventarsystem",
            "Wartungsvertrag",
            [
                "VertragsNr",
                "GeräteNr",
                "Vertragsart",
                "Beginn",
                "Ende",
                "Kosten_pro_Jahr",
            ],
            rows,
        )
    )

    # Wartungen
    rows = [
        [
            str(row["WartungsNr"]),
            str(row["GeräteNr"]),
            sql_date(row["Datum"]),
            sql_string(row["Wartungsart"]),
            sql_decimal(row["Kosten"]),
        ]
        for row in maintenance
    ]

    lines.append("-- Wartungen")
    lines.append(
        insert_statement(
            "src_inventarsystem",
            "Wartung",
            [
                "WartungsNr",
                "GeräteNr",
                "Datum",
                "Wartungsart",
                "Kosten",
            ],
            rows,
        )
    )

    # Kunden
    rows = [
        [
            str(row["KundenNr"]),
            sql_string(row["Kunden_Name"]),
            sql_string(row["Kundentyp"]),
        ]
        for row in customers
    ]

    lines.append("-- Kunden")
    lines.append(
        insert_statement(
            "src_ticketsystem",
            "Kunde",
            [
                "KundenNr",
                "Kunden_Name",
                "Kundentyp",
            ],
            rows,
        )
    )

    # Kundenbetreuer
    rows = [
        [
            str(row["BetreuerNr"]),
            str(row["KundenNr"]),
            sql_string(row["Name"]),
            sql_string(row["Team"]),
        ]
        for row in account_managers
    ]

    lines.append("-- Kundenbetreuer")
    lines.append(
        insert_statement(
            "src_ticketsystem",
            "Kundenbetreuer",
            [
                "BetreuerNr",
                "KundenNr",
                "Name",
                "Team",
            ],
            rows,
        )
    )

    # Mitarbeiter
    rows = [
        [
            str(row["MitarbeiterNr"]),
            sql_string(row["Name"]),
            sql_string(row["Team"]),
            sql_string(row["Rolle"]),
        ]
        for row in employees
    ]

    lines.append("-- Mitarbeiter")
    lines.append(
        insert_statement(
            "src_ticketsystem",
            "Mitarbeiter",
            [
                "MitarbeiterNr",
                "Name",
                "Team",
                "Rolle",
            ],
            rows,
        )
    )

    # Tickets
    rows = [
        [
            str(row["TicketNr"]),
            str(row["KundenNr"]),
            str(row["GeräteNr"]),
            sql_date(row["Erstellungsdatum"]),
            sql_string(row["Kategorie"]),
            sql_string(row["Priorität"]),
            sql_string(row["Status"]),
            str(row["SLA_Zielzeit_Minuten"]),
        ]
        for row in tickets
    ]

    lines.append("-- Tickets")
    lines.append(
        insert_statement(
            "src_ticketsystem",
            "Ticket",
            [
                "TicketNr",
                "KundenNr",
                "GeräteNr",
                "Erstellungsdatum",
                "Kategorie",
                "Priorität",
                "Status",
                "SLA_Zielzeit_Minuten",
            ],
            rows,
        )
    )

    # Bearbeitungen
    rows = [
        [
            str(row["BearbeitungsNr"]),
            str(row["TicketNr"]),
            str(row["MitarbeiterNr"]),
            sql_date(row["Datum"]),
            str(row["Bearbeitungszeit_Minuten"]),
            sql_string(row["Aktionstyp"]),
        ]
        for row in processings
    ]

    lines.append("-- Bearbeitungen")
    lines.append(
        insert_statement(
            "src_ticketsystem",
            "Bearbeitung",
            [
                "BearbeitungsNr",
                "TicketNr",
                "MitarbeiterNr",
                "Datum",
                "Bearbeitungszeit_Minuten",
                "Aktionstyp",
            ],
            rows,
        )
    )

    lines.append("COMMIT;")
    lines.append("")
    lines.append("-- =========================================================")
    lines.append("-- Ende der Beispieldaten")
    lines.append("-- =========================================================")
    lines.append("")

    OUTPUT_FILE.write_text("\n".join(lines), encoding="utf-8")

    return {
        "Standorte": len(locations),
        "Geräte": len(devices),
        "Wartungsverträge": len(contracts),
        "Wartungen": len(maintenance),
        "Kunden": len(customers),
        "Kundenbetreuer": len(account_managers),
        "Mitarbeiter": len(employees),
        "Tickets": len(tickets),
        "Bearbeitungen": len(processings),
    }


if __name__ == "__main__":
    counts = generate_sql()

    print()
    print("Beispieldaten wurden erfolgreich erzeugt.")
    print(f"SQL-Datei: {OUTPUT_FILE}")
    print(f"Seed: {SEED}")
    print()
    print("Erzeugte Datensätze:")
    for table, count in counts.items():
        print(f"  {table:20} {count:4}")
    print()
    print("Für einen anderen Lauf:")
    print("  python generate_data.py 4711")
