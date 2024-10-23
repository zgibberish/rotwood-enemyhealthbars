name = "Enemy Health Bars"
description = "Shows HP bar and values below rots."
author = "gibberish"
version = "1.0"
api_version = 10

dst_compatible = false
forge_compatible = false
gorge_compatible = false
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
rotwood_compatible = true

client_only_mod = true
all_clients_require_mod = false

configuration_options = {
    {
		name = "always_shown",
		label = "Display Mode",
		hover = "Choose whether or not enemy health bars are always shown or fade in/out dynamically.",
		options =	
		{
            {description = "Shown when damaged", data = 1},
			{description = "Always visible", data = 2},
		},
		default = 1,
	},
	{
		name = "show_values",
		label = "Display HP Values",
		hover = "Whether to show numeric HP values or not.",
		options =	
		{
			{description = "Hidden", data = 1},
            {description = "Shown", data = 2},
		},
		default = 2,
	},
}
