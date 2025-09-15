Config = {}

Config.RequiredCops = 2
Config.RequiredItem = "lockpick"

Config.Rewards = {
    { item = "metalscrap", label = "Phế liệu kim loại", min = 1, max = 3 },
    { item = "copper", label = "Đồng", min = 1, max = 3 },
    { item = "iron", label = "Sắt", min = 1, max = 3 },
    { item = "aluminum", label = "Nhôm", min = 1, max = 3 },
    { item = "steel", label = "Thép", min = 1, max = 3 },
}

Config.Objects = {
    { key="stopsign", label="Trộm Biển Báo", model="prop_sign_road_01a", prop="prop_sign_road_01a", item="stopsign", stealTime=20000, tradeRolls={min=2,max=4} },
    { key="walkingmansign", label="Trộm Biển Báo", model="prop_sign_road_05a", prop="prop_sign_road_05a", item="walkingmansign", stealTime=20000, tradeRolls={min=2,max=4} },
    { key="dontblockintersectionsign", label="Trộm Biển Báo", model="prop_sign_road_03e", prop="prop_sign_road_03e", item="dontblockintersectionsign", stealTime=20000, tradeRolls={min=2,max=4} },
    { key="leftturnsign", label="Trộm Biển Báo", model="prop_sign_road_05e", prop="prop_sign_road_05e", item="leftturnsign", stealTime=20000, tradeRolls={min=2,max=4} },
    { key="noparkingsign", label="Trộm Biển Báo", model="prop_sign_road_04a", prop="prop_sign_road_04a", item="noparkingsign", stealTime=20000, tradeRolls={min=2,max=4} },
    { key="notrespassingsign", label="Trộm Biển Báo", model="prop_sign_road_restriction_10", prop="prop_sign_road_restriction_10", item="notrespassingsign", stealTime=20000, tradeRolls={min=2,max=4} },
    { key="uturnsign", label="Trộm Biển Báo", model="prop_sign_road_03m", prop="prop_sign_road_03m", item="uturnsign", stealTime=20000, tradeRolls={min=2,max=4} },
    { key="rightturnsign", label="Trộm Biển Báo", model="prop_sign_road_05f", prop="prop_sign_road_05f", item="rightturnsign", stealTime=20000, tradeRolls={min=2,max=4} },
    { key="yieldsign", label="Trộm Biển Báo", model="prop_sign_road_02a", prop="prop_sign_road_02a", item="yieldsign", stealTime=20000, tradeRolls={min=2,max=4} },
    { key="parknmeter", label="Trộm Đồng hồ", model="prop_parknmeter_02", prop="prop_parknmeter_02", item="parknmeter", stealTime=20000, tradeRolls={min=2,max=4} },
}

Config.Target = { icon="fas fa-user-secret", label="Trộm" }
Config.ScrapZone = { coords=vec3(2332.43,3026.89,48.15), size=vec3(1.5,1,4.0), rotation=270 }

Config.AlertCopsEvent = nil
Config.OnStealSuccess = nil

