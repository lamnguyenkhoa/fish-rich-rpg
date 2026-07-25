extends Node

enum ItemType {
    NONE,
    CONSUMABLE = 1,
    EQUIPMENT = 2,
    KEY = 3,
    MISC = 4
}

enum ItemId {
    NONE,
    # FOOD
    FRIED_RICE = 1000,
    OCTO_BENTO = 1001,
    CHURCH_MEAL = 1002,
    # MEDICAL
    BANDAID = 2000,
    FIRST_AID_KIT = 2001,
    PREMIUM_MEDKIT = 2002,
    BODY_ENHANCE_DRUG = 2003,
    REFLEX_BOOSTER_DRINK = 2004,
    # INTERACTABLE EQUIPMENT
    SMARTPHONE = 9000
}

enum ServiceSpecialCase {
    NONE,
    NEXT_DAY = 100,
    SMUGGLE = 105,
    PAY_DEBT = 200,
    HOSPITAL_HELP_DESK = 300,
}


enum ItemSpecialCase {
    NONE,
    SMARTPHONE = 100
}