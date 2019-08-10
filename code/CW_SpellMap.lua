--[[
  MIT License

  Copyright (c) 2019 Michael Wiesendanger

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

local mod = rgcw
local me = {}
mod.spellMap = me

me.tag = "SpellMap"

local spellMap

--[[
  TODO Depending on what locale the client has a different implementation is used
  to normalize a spellname (this is determined once during addon load). This is done because this function is time critical
  and can be called a lot during fights with a lot of players.
]]--
if (GetLocale() == "deDE") then

  spellMap = {
    ["warrior"] = {
  		["blutrausch"] = {
  			["active"] = true,
  			["cooldown"] = 60,
  			["spellId"] = 2687,
  			["spellName"] = "Blutrausch",
  		},
  		["berserkerwut"] = {
  			["active"] = true,
  			["cooldown"] = 30,
  			["spellId"] = 18499,
  			["spellName"] = "Berserkerwut",
  		},
  		["abfangen"] = {
  			["cooldownWorstCase"] = 20,
  			["spellId"] = 20617,
  			["active"] = true,
  			["cooldown"] = 30,
  			["spellName"] = "Abfangen",
  		},
  		["sturmangriff"] = {
  			["active"] = true,
  			["cooldown"] = 15,
  			["spellId"] = 11578,
  			["spellName"] = "Sturmangriff",
  		},
  		["blutdurst"] = {
  			["active"] = true,
  			["cooldown"] = 6,
  			["spellId"] = 23894,
  			["spellName"] = "Blutdurst",
  		},
  		["todeswunsch"] = {
  			["active"] = true,
  			["cooldown"] = 180,
  			["spellId"] = 12328,
  			["spellName"] = "Todeswunsch",
  		}
  	},
  	["misc"] = {
  		["net_o_matik"] = {
  			["spellId"] = 13120,
  			["active"] = true,
  			["itemId"] = 10720,
  			["cooldown"] = 600,
  			["spellName"] = "Net-o-Matik",
  		},
  		["gnomen_raketenstiefel"] = {
  			["spellId"] = 13141,
  			["active"] = true,
  			["itemId"] = 10724,
  			["cooldown"] = 1800,
  			["spellName"] = "Gnomen-Raketenstiefel",
  		},
  		["schattenreflektor"] = {
  			["spellId"] = 23132,
  			["active"] = true,
  			["itemId"] = 18639,
  			["cooldown"] = 300,
  			["spellName"] = "Schattenreflektor",
  		},
  		["tollkuehnes_stuermen"] = {
  			["spellId"] = 22641,
  			["active"] = true,
  			["itemId"] = 10588,
  			["cooldown"] = 1200,
  			["spellName"] = "Tollkühnes Stürmen",
  		},
  		["feuerreflektor"] = {
  			["spellId"] = 23097,
  			["active"] = true,
  			["itemId"] = 18638,
  			["cooldown"] = 300,
  			["spellName"] = "Feuerreflektor",
  		},
  		["frostreflektor"] = {
  			["spellId"] = 23131,
  			["active"] = true,
  			["itemId"] = 18634,
  			["cooldown"] = 300,
  			["spellName"] = "Frostreflektor",
  		},
  		["goblin_raketenstiefel"] = {
  			["spellId"] = 8892,
  			["active"] = true,
  			["itemId"] = 7189,
  			["cooldown"] = 300,
  			["spellName"] = "Goblin-Raketenstiefel",
  		}
  	},
  	["shaman"] = {
  		["totem_der_feuernova"] = {
  			["active"] = true,
  			["cooldown"] = 15,
  			["spellId"] = 11315,
  			["spellName"] = "Totem der Feuernova",
  		},
  		["frostschock"] = {
  			["cooldownWorstCase"] = 5,
  			["spellId"] = 10473,
  			["active"] = true,
  			["cooldown"] = 6,
  			["spellName"] = "Frostschock",
  		},
  		["flammenschock"] = {
  			["cooldownWorstCase"] = 5,
  			["spellId"] = 29228,
  			["active"] = true,
  			["cooldown"] = 6,
  			["spellName"] = "Flammenschock",
  		},
  		["totem_der_erdung"] = {
  			["active"] = true,
  			["cooldown"] = 15,
  			["spellId"] = 8177,
  			["spellName"] = "Totem der Erdung",
  		},
  		["elementarbeherrschung"] = {
  			["active"] = true,
  			["cooldown"] = 180,
  			["spellId"] = 16166,
  			["spellName"] = "Elementarbeherrschung",
  		},
  		["schnelligkeit_der_natur"] = {
  			["active"] = true,
  			["cooldown"] = 180,
  			["spellId"] = 16188,
  			["spellName"] = "Schnelligkeit der Natur",
  		},
  		["totem_der_erdbindung"] = {
  			["active"] = true,
  			["cooldown"] = 15,
  			["spellId"] = 2484,
  			["spellName"] = "Totem der Erdbindung",
  		},
  		["erdschock"] = {
  			["cooldownWorstCase"] = 5,
  			["spellId"] = 10414,
  			["active"] = true,
  			["cooldown"] = 6,
  			["spellName"] = "Erdschock",
  		}
  	},
  	["rogue"] = {
  		["entrinnen"] = {
  			["active"] = true,
  			["cooldown"] = 300,
  			["spellId"] = 5277,
  			["spellName"] = "Entrinnen",
  		},
  		["solarplexus"] = {
  			["active"] = true,
  			["cooldown"] = 10,
  			["spellId"] = 11286,
  			["spellName"] = "Solarplexus",
  		},
  		["adrenalinrausch"] = {
  			["active"] = true,
  			["cooldown"] = 300,
  			["spellId"] = 13750,
  			["spellName"] = "Adrenalinrausch",
  		},
  		["tritt"] = {
  			["active"] = true,
  			["cooldown"] = 10,
  			["spellId"] = 1769,
  			["spellName"] = "Tritt",
  		},
  		["riposte"] = {
  			["active"] = true,
  			["cooldown"] = 6,
  			["spellId"] = 14251,
  			["spellName"] = "Riposte",
  		},
  		["verschwinden"] = {
  			["active"] = true,
  			["cooldown"] = 300,
  			["spellId"] = 1857,
  			["spellName"] = "Verschwinden",
  		},
  		["sprinten"] = {
  			["active"] = true,
  			["cooldown"] = 300,
  			["spellId"] = 11305,
  			["spellName"] = "Sprinten",
  		},
  		["klingenwirbel"] = {
  			["active"] = true,
  			["cooldown"] = 120,
  			["spellId"] = 13877,
  			["spellName"] = "Klingenwirbel",
  		},
  		["kaltbluetigkeit"] = {
  			["active"] = true,
  			["cooldown"] = 180,
  			["spellId"] = 14177,
  			["spellName"] = "Kaltblütigkeit",
  		},
  		["nierenhieb"] = {
  			["active"] = true,
  			["cooldown"] = 20,
  			["spellId"] = 8643,
  			["spellName"] = "Nierenhieb",
  		},
  		["blenden"] = {
  			["active"] = true,
  			["cooldown"] = 300,
  			["spellId"] = 2094,
  			["spellName"] = "Blenden",
  		}
  	},
  	["mage"] = {
  		["eisbarriere"] = {
  			["active"] = true,
  			["cooldown"] = 30,
  			["spellId"] = 13033,
  			["spellName"] = "Eisbarriere",
  		},
  		["eisblock"] = {
  			["active"] = true,
  			["cooldown"] = 300,
  			["spellId"] = 11958,
  			["spellName"] = "Eisblock",
  		},
  		["verbrennung"] = {
  			["active"] = true,
  			["cooldown"] = 180,
  			["spellId"] = 11129,
  			["spellName"] = "Verbrennung",
  		},
  		["blinzeln"] = {
  			["cooldownWorstCase"] = 13,
  			["spellId"] = 1953,
  			["active"] = true,
  			["cooldown"] = 15,
  			["spellName"] = "Blinzeln",
  		},
  		["kaeltekegel"] = {
  			["active"] = true,
  			["cooldown"] = 10,
  			["spellId"] = 10161,
  			["spellName"] = "Kältekegel",
  		},
  		["frostzauberschutz"] = {
  			["active"] = true,
  			["cooldown"] = 30,
  			["spellId"] = 28609,
  			["spellName"] = "Frostzauberschutz",
  		},
  		["feuerschlag"] = {
  			["cooldownWorstCase"] = 6.5,
  			["spellId"] = 10199,
  			["active"] = true,
  			["cooldown"] = 8,
  			["spellName"] = "Feuerschlag",
  		},
  		["gegenzauber"] = {
  			["active"] = true,
  			["cooldown"] = 30,
  			["spellId"] = 2139,
  			["spellName"] = "Gegenzauber",
  		},
  		["feuerzauberschutz"] = {
  			["active"] = true,
  			["cooldown"] = 30,
  			["spellId"] = 10225,
  			["spellName"] = "Feuerzauberschutz",
  		},
  		["geistesgegenwart"] = {
  			["active"] = true,
  			["cooldown"] = 180,
  			["spellId"] = 12043,
  			["spellName"] = "Geistesgegenwart",
  		}
  	},
  	["warlock"] = {
  		["seelenfeuer"] = {
  			["active"] = true,
  			["cooldown"] = 60,
  			["spellId"] = 17924,
  			["spellName"] = "Seelenfeuer",
  		},
  		["schreckensgeheul"] = {
  			["active"] = true,
  			["cooldown"] = 40,
  			["spellId"] = 17928,
  			["spellName"] = "Schreckensgeheul",
  		},
  		["fluch_verstaerken"] = {
  			["active"] = true,
  			["cooldown"] = 180,
  			["spellId"] = 18288,
  			["spellName"] = "Fluch verstärken",
  		},
  		["schattenbrand"] = {
  			["active"] = true,
  			["cooldown"] = 15,
  			["spellId"] = 18871,
  			["spellName"] = "Schattenbrand",
  		},
  		["schattenzauberschutz"] = {
  			["active"] = true,
  			["cooldown"] = 30,
  			["spellId"] = 28610,
  			["spellName"] = "Schattenzauberschutz",
  		},
  		["todesmantel"] = {
  			["active"] = true,
  			["cooldown"] = 120,
  			["spellId"] = 17926,
  			["spellName"] = "Todesmantel",
  		},
  		["teufelsbeherrschung"] = {
  			["active"] = true,
  			["cooldown"] = 900,
  			["spellId"] = 18708,
  			["spellName"] = "Teufelsbeherrschung",
  		},
  		["feuersbrunst"] = {
  			["active"] = true,
  			["cooldown"] = 10,
  			["spellId"] = 18932,
  			["spellName"] = "Feuersbrunst",
  		}
  	},
  	["druid"] = {
  		["rasende_regeneration"] = {
  			["active"] = true,
  			["cooldown"] = 180,
  			["spellId"] = 22896,
  			["spellName"] = "Rasende Regeneration",
  		},
  		["gelassenheit"] = {
  			["active"] = true,
  			["cooldown"] = 300,
  			["spellId"] = 9863,
  			["spellName"] = "Gelassenheit",
  		},
  		["hieb"] = {
  			["active"] = true,
  			["cooldown"] = 60,
  			["spellId"] = 8983,
  			["spellName"] = "Hieb",
  		},
  		["wiedergeburt"] = {
  			["active"] = true,
  			["cooldown"] = 1800,
  			["spellId"] = 20748,
  			["spellName"] = "Wiedergeburt",
  		},
  		["schnelligkeit_der_natur"] = {
  			["active"] = true,
  			["cooldown"] = 180,
  			["spellId"] = 17116,
  			["spellName"] = "Schnelligkeit der Natur",
  		},
  		["wutanfall"] = {
  			["active"] = true,
  			["cooldown"] = 60,
  			["spellId"] = 5229,
  			["spellName"] = "Wutanfall",
  		},
  		["spurt"] = {
  			["active"] = true,
  			["cooldown"] = 300,
  			["spellId"] = 9821,
  			["spellName"] = "Spurt",
  		},
  		["anregen"] = {
  			["active"] = true,
  			["cooldown"] = 360,
  			["spellId"] = 29166,
  			["spellName"] = "Anregen",
  		},
  		["griff_der_natur"] = {
  			["active"] = true,
  			["cooldown"] = 60,
  			["spellId"] = 17329,
  			["spellName"] = "Griff der Natur",
  		},
  		["wilde_attacke"] = {
  			["active"] = true,
  			["cooldown"] = 15,
  			["spellId"] = 16979,
  			["spellName"] = "Wilde Attacke",
  		},
  		["rasche_heilung"] = {
  			["active"] = true,
  			["cooldown"] = 15,
  			["spellId"] = 18562,
  			["spellName"] = "Rasche Heilung",
  		},
  		["baumrinde"] = {
  			["active"] = true,
  			["cooldown"] = 60,
  			["spellId"] = 22812,
  			["spellName"] = "Baumrinde",
  		}
  	},
  	["priest"] = {
  		["seele_der_macht"] = {
  			["active"] = true,
  			["cooldown"] = 180,
  			["spellId"] = 10060,
  			["spellName"] = "Seele der Macht",
  		},
  		["psychischer_schrei"] = {
  			["cooldownWorstCase"] = 26,
  			["spellId"] = 10890,
  			["active"] = true,
  			["cooldown"] = 30,
  			["spellName"] = "Psychischer Schrei",
  		},
  		["innerer_fokus"] = {
  			["active"] = true,
  			["cooldown"] = 180,
  			["spellId"] = 14751,
  			["spellName"] = "Innerer Fokus",
  		},
  		["elunes_anmut"] = {
  			["active"] = true,
  			["cooldown"] = 300,
  			["spellId"] = 19293,
  			["spellName"] = "Elunes Anmut",
  		},
  		["verschlingende_seuche"] = {
  			["active"] = true,
  			["cooldown"] = 180,
  			["spellId"] = 19280,
  			["spellName"] = "Verschlingende Seuche",
  		},
  		["furchtzauberschutz"] = {
  			["active"] = true,
  			["cooldown"] = 30,
  			["spellId"] = 6346,
  			["spellName"] = "Furchtzauberschutz",
  		},
  		["gedankenschlag"] = {
  			["cooldownWorstCase"] = 5.5,
  			["spellId"] = 10947,
  			["active"] = true,
  			["cooldown"] = 8,
  			["spellName"] = "Gedankenschlag",
  		},
  		["stille"] = {
  			["active"] = true,
  			["cooldown"] = 45,
  			["spellId"] = 15487,
  			["spellName"] = "Stille",
  		},
  		["machtwort_schild"] = {
  			["active"] = true,
  			["cooldown"] = 4,
  			["spellId"] = 10901,
  			["spellName"] = "Machtwort: Schild",
  		}
  	},
  	["hunter"] = {
  		["streuschuss"] = {
  			["active"] = true,
  			["cooldown"] = 30,
  			["spellId"] = 19503,
  			["spellName"] = "Streuschuss",
  		},
  		["erschuetternder_schuss"] = {
  			["active"] = true,
  			["cooldown"] = 12,
  			["spellId"] = 5116,
  			["spellName"] = "Erschütternder Schuss",
  		},
  		["gegenangriff"] = {
  			["active"] = true,
  			["cooldown"] = 5,
  			["spellId"] = 20910,
  			["spellName"] = "Gegenangriff",
  		},
  		["arkaner_schuss"] = {
  			["cooldownWorstCase"] = 5,
  			["spellId"] = 14287,
  			["active"] = true,
  			["cooldown"] = 6,
  			["spellName"] = "Arkaner Schuss",
  		},
  		["gezielter_schuss"] = {
  			["active"] = true,
  			["cooldown"] = 6,
  			["spellId"] = 20904,
  			["spellName"] = "Gezielter Schuss",
  		},
  		["schnellfeuer"] = {
  			["active"] = true,
  			["cooldown"] = 300,
  			["spellId"] = 3045,
  			["spellName"] = "Schnellfeuer",
  		},
  		["zorn_des_wildtiers"] = {
  			["active"] = true,
  			["cooldown"] = 120,
  			["spellId"] = 19574,
  			["spellName"] = "Zorn des Wildtiers",
  		},
  		["abschreckung"] = {
  			["active"] = true,
  			["cooldown"] = 300,
  			["spellId"] = 19263,
  			["spellName"] = "Abschreckung",
  		},
  		["stich_des_fluegeldrachen"] = {
  			["active"] = true,
  			["cooldown"] = 120,
  			["spellId"] = 24132,
  			["spellName"] = "Stich des Flügeldrachen",
  		},
  		["leuchtfeuer"] = {
  			["active"] = true,
  			["cooldown"] = 15,
  			["spellId"] = 1543,
  			["spellName"] = "Leuchtfeuer",
  		},
  		["einschuechterung"] = {
  			["active"] = true,
  			["cooldown"] = 60,
  			["spellId"] = 19577,
  			["spellName"] = "Einschüchterung",
  		}
  	},
  	["racials"] = {
  		["wille_der_verlassenen"] = {
  			["active"] = true,
  			["cooldown"] = 120,
  			["spellId"] = 7744,
  			["spellName"] = "Wille der Verlassenen",
  		},
  		["kriegsdonner"] = {
  			["active"] = true,
  			["cooldown"] = 120,
  			["spellId"] = 20549,
  			["spellName"] = "Kriegsdonner",
  		},
  		["kochendes_blut"] = {
  			["active"] = true,
  			["cooldown"] = 120,
  			["spellId"] = 20572,
  			["spellName"] = "Kochendes Blut",
  		},
  		["berserker"] = {
  			["active"] = true,
  			["cooldown"] = 180,
  			["spellId"] = 26296,
  			["spellName"] = "Berserker",
  		},
  		["wachsamkeit"] = {
  			["active"] = true,
  			["cooldown"] = 180,
  			["spellId"] = 20600,
  			["spellName"] = "Wachsamkeit",
  		},
  		["entfesselungskuenstler"] = {
  			["active"] = true,
  			["cooldown"] = 60,
  			["spellId"] = 20589,
  			["spellName"] = "Entfesselungskünstler",
  		},
  		["steingestalt"] = {
  			["active"] = true,
  			["cooldown"] = 180,
  			["spellId"] = 20594,
  			["spellName"] = "Steingestalt",
  		}
  	},
  	["paladin"] = {
  		["segen_des_schutzes"] = {
  			["active"] = true,
  			["cooldown"] = 180,
  			["spellId"] = 10278,
  			["spellName"] = "Segen des Schutzes",
  		},
  		["segen_der_freiheit"] = {
  			["active"] = true,
  			["cooldown"] = 20,
  			["spellId"] = 1044,
  			["spellName"] = "Segen der Freiheit",
  		},
  		["hammer_des_zorns"] = {
  			["active"] = true,
  			["cooldown"] = 6,
  			["spellId"] = 24239,
  			["spellName"] = "Hammer des Zorns",
  		},
  		["hammer_der_gerechtigkeit"] = {
  			["cooldownWorstCase"] = 45,
  			["spellId"] = 10308,
  			["active"] = true,
  			["cooldown"] = 60,
  			["spellName"] = "Hammer der Gerechtigkeit",
  		},
  		["heiliger_schock"] = {
  			["active"] = true,
  			["cooldown"] = 30,
  			["spellId"] = 20930,
  			["spellName"] = "Heiliger Schock",
  		},
  		["goettliche_gunst"] = {
  			["active"] = true,
  			["cooldown"] = 120,
  			["spellId"] = 20216,
  			["spellName"] = "Göttliche Gunst",
  		},
  		["busse"] = {
  			["active"] = true,
  			["cooldown"] = 60,
  			["spellId"] = 20066,
  			["spellName"] = "Buße",
  		},
  		["goettlicher_schutz"] = {
  			["active"] = true,
  			["cooldown"] = 300,
  			["spellId"] = 5573,
  			["spellName"] = "Göttlicher Schutz",
  		},
  		["gottesschild"] = {
  			["active"] = true,
  			["cooldown"] = 300,
  			["spellId"] = 1020,
  			["spellName"] = "Gottesschild",
  		},
  		["handauflegung"] = {
  			["cooldownWorstCase"] = 2400,
  			["spellId"] = 10310,
  			["active"] = true,
  			["cooldown"] = 3600,
  			["spellName"] = "Handauflegung",
  		}
  	}
  }
else
  --[[
    ["class"] = {
      The idea behind using spellId is to have the easiest way to find a casted spell in the list.
      This should be faster than searching through the list until a match is found.
      [spellId] = {
        ["spellName"] = spellName,
          - {string} Name of the spell how it shows in the spellbook
        ["rank"] = rank,
          - {number | nil} The rank of the spell often not available
        ["cooldown"] = cooldown,
          - {number} Cooldown of the spell in seconds without any modifiers such as talent or items
        ["cooldownWorstCase"] = cooldownWorstCase,
          - {number} Optional worst case cooldown for the cooldown. Assuming the enemy player has its spell fully reduced with either a talent or an item.
          Note: if an item is unlikely to be worn by players it might get omitted here
        ["active"] = true
          - {boolean} Whether the spell is active and tracked or not
      }
    }
  ]]--
  spellMap = {
    ["priest"] = {
      ["psychic_scream"] = {
        ["spellName"] = "Psychic Scream",
        ["spellId"] = 10890,
        ["cooldown"] = 30,
        ["cooldownWorstCase"] = 26,
        ["active"] = true
      },
      ["devouring_plague"] = {
        ["spellName"] = "Devouring Plague",
        ["spellId"] = 19280,
        ["cooldown"] = 180,
        ["active"] = true
      },
      ["elunes_grace"] = {
        ["spellName"] = "Elune's Grace",
        ["spellId"] = 19293,
        ["cooldown"] = 300,
        ["active"] = true
      },
      ["fear_ward"] = {
        ["spellName"] = "Fear Ward",
        ["spellId"] = 6346,
        ["cooldown"] = 30,
        ["active"] = true
      },
      ["inner_focus"] = {
        ["spellName"] = "Inner Focus",
        ["spellId"] = 14751,
        ["cooldown"] = 180,
        ["active"] = true
      },
      ["mind_blast"] = {
        ["spellName"] = "Mind Blast",
        ["spellId"] = 10947,
        ["cooldown"] = 8,
        ["cooldownWorstCase"] = 5.5,
        ["active"] = true
      },
      ["power_infusion"] = {
        ["spellName"] = "Power Infusion",
        ["spellId"] = 10060,
        ["cooldown"] = 180,
        ["active"] = true
      },
      ["power_word_shield"] = {
        ["spellName"] = "Power Word: Shield",
        ["spellId"] = 10901,
        ["cooldown"] = 4,
        ["active"] = true
      },
      ["silence"] = {
        ["spellName"] = "Silence",
        ["spellId"] = 15487,
        ["cooldown"] = 45,
        ["active"] = true
      }
    },
    ["rogue"] = {
      ["adrenaline_rush"] = {
        ["spellName"] = "Adrenaline Rush",
        ["spellId"] = 13750,
        ["cooldown"] = 300,
        ["active"] = true
      },
      ["blade_flurry"] = {
        ["spellName"] = "Blade Flurry",
        ["spellId"] = 13877,
        ["cooldown"] = 120,
        ["active"] = true
      },
      ["blind"] = {
        ["spellName"] = "Blind",
        ["spellId"] = 2094,
        ["cooldown"] = 300,
        ["active"] = true
      },
      ["cold_blood"] = {
        ["spellName"] = "Cold Blood",
        ["spellId"] = 14177,
        ["cooldown"] = 180,
        ["active"] = true
      },
      ["evasion"] = {
        ["spellName"] = "Evasion",
        ["spellId"] = 5277,
        ["cooldown"] = 300,
        ["active"] = true
      },
      ["gouge"] = {
        ["spellName"] = "Gouge",
        ["spellId"] = 11286,
        ["cooldown"] = 10,
        ["active"] = true
      },
      ["kick"] = {
        ["spellName"] = "Kick",
        ["spellId"] = 1769,
        ["cooldown"] = 10,
        ["active"] = true
      },
      ["kidney_shot"] = {
        ["spellName"] = "Kidney Shot",
        ["spellId"] = 8643,
        ["cooldown"] = 20,
        ["active"] = true
      },
      ["riposte"] = {
        ["spellName"] = "Riposte",
        ["spellId"] = 14251,
        ["cooldown"] = 6,
        ["active"] = true
      },
      ["sprint"] = {
        ["spellName"] = "Sprint",
        ["spellId"] = 11305,
        ["cooldown"] = 300,
        ["active"] = true
      },
      ["vanish"] = {
        ["spellName"] = "Vanish",
        ["spellId"] = 1857,
        ["cooldown"] = 300,
        ["active"] = true
      }
    },
    ["mage"] = {
      ["combustion"] = {
        ["spellName"] = "Combustion",
        ["spellId"] = 11129,
        ["cooldown"] = 180,
        ["active"] = true
      },
      ["cone_of_cold"] = {
        ["spellName"] = "Cone of Cold",
        ["spellId"] = 10161,
        ["cooldown"] = 10,
        ["active"] = true
      },
      ["counterspell"] = {
        ["spellName"] = "Counterspell",
        ["spellId"] = 2139,
        ["cooldown"] = 30,
        ["active"] = true
      },
      ["presence_of_mind"] = {
        ["spellName"] = "Presence of Mind",
        ["spellId"] = 12043,
        ["cooldown"] = 180,
        ["active"] = true
      },
      ["blink"] = {
        ["spellName"] = "Blink",
        ["spellId"] = 1953,
        ["cooldown"] = 15,
        ["cooldownWorstCase"] = 13,
        ["active"] = true
      },
      ["fire_blast"] = {
        ["spellName"] = "Fire Blast",
        ["spellId"] = 10199,
        ["cooldown"] = 8,
        ["cooldownWorstCase"] = 6.5,
        ["active"] = true
      },
      ["fire_ward"] = {
        ["spellName"] = "Fire Ward",
        ["spellId"] = 10225,
        ["cooldown"] = 30,
        ["active"] = true
      },
      ["frost_ward"] = {
        ["spellName"] = "Frost Ward",
        ["spellId"] = 28609,
        ["cooldown"] = 30,
        ["active"] = true
      },
      ["ice_barrier"] = {
        ["spellName"] = "Ice Barrier",
        ["spellId"] = 13033,
        ["cooldown"] = 30,
        ["active"] = true
      },
      ["ice_block"] = {
        ["spellName"] = "Ice Block",
        ["spellId"] = 11958,
        ["cooldown"] = 300,
        ["active"] = true
      }
    },
    ["hunter"] = {
      ["aimed_shot"] = {
        ["spellName"] = "Aimed Shot",
        ["spellId"] = 20904,
        ["cooldown"] = 6,
        ["active"] = true
      },
      ["arcane_shot"] = {
        ["spellName"] = "Arcane Shot",
        ["spellId"] = 14287,
        ["cooldown"] = 6,
        ["cooldownWorstCase"] = 5,
        ["active"] = true
      },
      ["bestial_wrath"] = {
        ["spellName"] = "Bestial Wrath",
        ["spellId"] = 19574,
        ["cooldown"] = 120,
        ["active"] = true
      },
      ["concussive_shot"] = {
        ["spellName"] = "Concussive Shot",
        ["spellId"] = 5116,
        ["cooldown"] = 12,
        ["active"] = true
      },
      ["counterattack"] = {
        ["spellName"] = "Counterattack",
        ["spellId"] = 20910,
        ["cooldown"] = 5,
        ["active"] = true
      },
      ["rapid_fire"] = {
        ["spellName"] = "Rapid Fire",
        ["spellId"] = 3045,
        ["cooldown"] = 300,
        ["active"] = true
      },
      ["scatter_shot"] = {
        ["spellName"] = "Scatter Shot",
        ["spellId"] = 19503,
        ["cooldown"] = 30,
        ["active"] = true
      },
      ["deterrence"] = {
        ["spellName"] = "Deterrence",
        ["spellId"] = 19263,
        ["cooldown"] = 300,
        ["active"] = true
      },
      ["wyvern_sting"] = {
        ["spellName"] = "Wyvern Sting",
        ["spellId"] = 24132,
        ["cooldown"] = 120,
        ["active"] = true
      },
      ["initmidation"] = {
        ["spellName"] = "Intimidation",
        ["spellId"] = 19577,
        ["cooldown"] = 60,
        ["active"] = true
      },
      ["flare"] = {
        ["spellName"] = "Flare",
        ["spellId"] = 1543,
        ["cooldown"] = 15,
        ["active"] = true
      }
    },
    ["warlock"] = {
      ["amplify_curse"] = {
        ["spellName"] = "Amplify Curse",
        ["spellId"] = 18288,
        ["cooldown"] = 180,
        ["active"] = true
      },
      ["death_coil"] = {
        ["spellName"] = "Death Coil",
        ["spellId"] = 17926,
        ["cooldown"] = 120,
        ["active"] = true
      },
      ["howl_of_terror"] = {
        ["spellName"] = "Howl of Terror",
        ["spellId"] = 17928,
        ["cooldown"] = 40,
        ["active"] = true
      },
      ["shadow_ward"] = {
        ["spellName"] = "Shadow Ward",
        ["spellId"] = 28610,
        ["cooldown"] = 30,
        ["active"] = true
      },
      ["soul_fire"] = {
        ["spellName"] = "Soul Fire",
        ["spellId"] = 17924,
        ["cooldown"] = 60,
        ["active"] = true
      },
      ["fel_domination"] = {
        ["spellName"] = "Fel Domination",
        ["spellId"] = 18708,
        ["cooldown"] = 900,
        ["active"] = true
      },
      ["shadowburn"] = {
        ["spellName"] = "Shadowburn",
        ["spellId"] = 18871,
        ["cooldown"] = 15,
        ["active"] = true
      },
      ["conflagrate"] = {
        ["spellName"] = "Conflagrate",
        ["spellId"] = 18932,
        ["cooldown"] = 10,
        ["active"] = true
      }
    },
    ["paladin"] = {
      ["blessing_of_freedom"] = {
        ["spellName"] = "Blessing of Freedom",
        ["spellId"] = 1044,
        ["cooldown"] = 20,
        ["active"] = true
      },
      ["blessing_of_protection"] = {
        ["spellName"] = "Blessing of Protection",
        ["spellId"] = 10278,
        ["cooldown"] = 180,
        ["active"] = true
      },
      ["divine_shield"] = {
        ["spellName"] = "Divine Shield",
        ["spellId"] = 1020,
        ["cooldown"] = 300,
        ["active"] = true
      },
      ["divine_protection"] = {
        ["spellName"] = "Divine Protection",
        ["spellId"] = 5573,
        ["cooldown"] = 300,
        ["active"] = true
      },
      ["hammer_of_justice"] = {
        ["spellName"] = "Hammer of Justice",
        ["spellId"] = 10308,
        ["cooldown"] = 60,
        ["cooldownWorstCase"] = 45,
        ["active"] = true
      },
      ["repentance"] = {
        ["spellName"] = "Repentance",
        ["spellId"] = 20066,
        ["cooldown"] = 60,
        ["active"] = true
      },
      ["divine_favor"] = {
        ["spellName"] = "Divine Favor",
        ["spellId"] = 20216,
        ["cooldown"] = 120,
        ["active"] = true
      },
      ["hammer_of_wrath"] = {
        ["spellName"] = "Hammer of Wrath",
        ["spellId"] = 24239,
        ["cooldown"] = 6,
        ["active"] = true
      },
      ["holy_shock"] = {
        ["spellName"] = "Holy Shock",
        ["spellId"] = 20930,
        ["cooldown"] = 30,
        ["active"] = true
      },
      ["lay_on_hands"] = {
        ["spellName"] = "Lay on Hands",
        ["spellId"] = 10310,
        ["cooldown"] = 3600,
        ["cooldownWorstCase"] = 2400,
        ["active"] = true
      }
    },
    ["druid"] = {
      ["bash"] = {
        ["spellName"] = "Bash",
        ["spellId"] = 8983,
        ["cooldown"] = 60,
        ["active"] = true
      },
      ["feral_charge"] = {
        ["spellName"] = "Feral Charge",
        ["spellId"] = 16979,
        ["cooldown"] = 15,
        ["active"] = true
      },
      ["frenzied_regeneration"] = {
        ["spellName"] = "Frenzied Regeneration",
        ["spellId"] = 22896,
        ["cooldown"] = 180,
        ["active"] = true
      },
      ["natures_swiftness"] = {
        ["spellName"] = "Nature's Swiftness",
        ["spellId"] = 17116,
        ["cooldown"] = 180,
        ["active"] = true
      },
      ["innervate"] = {
        ["spellName"] = "Innervate",
        ["spellId"] = 29166,
        ["cooldown"] = 360,
        ["active"] = true
      },
      ["swiftmend"] = {
        ["spellName"] = "Swiftmend",
        ["spellId"] = 18562,
        ["cooldown"] = 15,
        ["active"] = true
      },
      ["barkskin"] = {
        ["spellName"] = "Barkskin",
        ["spellId"] = 22812,
        ["cooldown"] = 60,
        ["active"] = true
      },
      ["dash"] = {
        ["spellName"] = "Dash",
        ["spellId"] = 9821,
        ["cooldown"] = 300,
        ["active"] = true
      },
      ["enrage"] = {
        ["spellName"] = "Enrage",
        ["spellId"] = 5229,
        ["cooldown"] = 60,
        ["active"] = true
      },
      ["rebirth"] = {
        ["spellName"] = "Rebirth",
        ["spellId"] = 20748,
        ["cooldown"] = 1800,
        ["active"] = true
      },
      ["tranquility"] = {
        ["spellName"] = "Tranquility",
        ["spellId"] = 9863,
        ["cooldown"] = 300,
        ["active"] = true
      },
      ["natures_grasp"] = {
        ["spellName"] = "Nature's Grasp",
        ["spellId"] = 17329,
        ["cooldown"] = 60,
        ["active"] = true
      }
    },
    -- TODO link shock spells together on same cooldown
    ["shaman"] = {
      ["earth_shock"] = {
        ["spellName"] = "Earth Shock",
        ["spellId"] = 10414,
        ["cooldown"] = 6,
        ["cooldownWorstCase"] = 5,
        ["active"] = true
      },
      ["frost_shock"] = {
        ["spellName"] = "Frost Shock",
        ["spellId"] = 10473,
        ["cooldown"] = 6,
        ["cooldownWorstCase"] = 5,
        ["active"] = true
      },
      ["flame_shock"] = {
        ["spellName"] = "Flame Shock",
        ["spellId"] = 29228,
        ["cooldown"] = 6,
        ["cooldownWorstCase"] = 5,
        ["active"] = true
      },
      ["elemental_mastery"] = {
        ["spellName"] = "Elemental Mastery",
        ["spellId"] = 16166,
        ["cooldown"] = 180,
        ["active"] = true
      },
      ["fire_nova_totem"] = {
        ["spellName"] = "Fire Nova Totem",
        ["spellId"] = 11315,
        ["cooldown"] = 15,
        ["active"] = true
      },
      ["grounding_totem"] = {
        ["spellName"] = "Grounding Totem",
        ["spellId"] = 8177,
        ["cooldown"] = 15,
        ["active"] = true
      },
      ["earthbind_totem"] = {
        ["spellName"] = "Earthbind Totem",
        ["spellId"] = 2484,
        ["cooldown"] = 15,
        ["active"] = true
      },
      ["natures_swiftness"] = {
        ["spellName"] = "Nature's Swiftness",
        ["spellId"] = 16188,
        ["cooldown"] = 180,
        ["active"] = true
      }
    },
    ["warrior"] = {
      ["berserker_rage"] = {
        ["spellName"] = "Berserker Rage",
        ["spellId"] = 18499,
        ["cooldown"] = 30,
        ["active"] = true
      },
      ["bloodrage"] = {
        ["spellName"] = "Bloodrage",
        ["spellId"] = 2687,
        ["cooldown"] = 60,
        ["active"] = true
      },
      ["bloodthirst"] = {
        ["spellName"] = "Bloodthirst",
        ["spellId"] = 23894,
        ["cooldown"] = 6,
        ["active"] = true
      },
      ["death_wish"] = {
        ["spellName"] = "Death Wish",
        ["spellId"] = 12328,
        ["cooldown"] = 180,
        ["active"] = true
      },
      ["intercept"] = {
        ["spellName"] = "Intercept",
        ["spellId"] = 20617,
        ["cooldown"] = 30,
        ["cooldownWorstCase"] = 20,
        ["active"] = true
      },
      ["charge"] = {
        ["spellName"] = "Charge",
        ["spellId"] = 11578,
        ["rank"] = 1,
        ["cooldown"] = 15,
        ["active"] = true
      }
    },
    ["racials"] = {
      ["escaoe_artis"] = {
        ["spellName"] = "Escape Artist",
        ["spellId"] = 20589,
        ["cooldown"] = 60,
        ["active"] = true
      },
      ["perception"] = {
        ["spellName"] = "Perception",
        ["spellId"] = 20600,
        ["cooldown"] = 180,
        ["active"] = true
      },
      ["stoneform"] = {
        ["spellName"] = "Stoneform",
        ["spellId"] = 20594,
        ["cooldown"] = 180,
        ["active"] = true
      },
      ["will_of_the_forsaken"] = {
        ["spellName"] = "Will of the Forsaken",
        ["spellId"] = 7744,
        ["cooldown"] = 120,
        ["active"] = true
      },
      ["war_stomp"] = {
        ["spellName"] = "War Stomp",
        ["spellId"] = 20549,
        ["cooldown"] = 120,
        ["active"] = true
      },
      ["blood_fury"] = {
        ["spellName"] = "Blood Fury",
        ["spellId"] = 20572,
        ["cooldown"] = 120,
        ["active"] = true
      },
      ["berserking"] = {
        ["spellName"] = "Berserking",
        ["spellId"] = 26296,
        ["cooldown"] = 180,
        ["active"] = true
      }
    },
    --[[
      TODO might need an additonal property here for the item icon because the spell
      itself might not give it away which item was used
    ]]--
    ["misc"] = {
      ["shadow_reflector"] = {
        ["spellName"] = "Ultra-Flash Shadow Reflector",
        ["spellId"] = 23132,
        ["itemId"] = 18639,
        ["cooldown"] = 300,
        ["active"] = true
      },
      ["frost_reflector"] = {
        ["spellName"] = "Gyrofreeze Ice Reflector",
        ["spellId"] = 23131,
        ["itemId"] = 18634,
        ["cooldown"] = 300,
        ["active"] = true
      },
      ["fire_reflector"] = {
        ["spellName"] = "Hyper-Radiant Flame Reflector",
        ["spellId"] = 23097,
        ["itemId"] = 18638,
        ["cooldown"] = 300,
        ["active"] = true
      },
      -- used 22641 by both goblin and viking helmet
      ["reckless_charge"] = {
        ["spellName"] = "Goblin Rocket Helmet",
        ["spellId"] = 22641,
        ["itemId"] = 10588,
        ["cooldown"] = 1200,
        ["active"] = true
      },
      ["gnomish_rocket_boots"] = {
        ["spellName"] = "Gnomish Rocket Boots",
        ["spellId"] = 13141,
        ["itemId"] = 10724,
        ["cooldown"] = 1800,
        ["active"] = true
      },
      ["goblin_rocket_boots"] = {
        ["spellName"] = "Goblin Rocket Boots",
        ["spellId"] = 8892,
        ["itemId"] = 7189,
        ["cooldown"] = 300,
        ["active"] = true
      },
      ["net_o_matic"] = {
        ["spellName"] = "Gnomish Net-o-Matic Projector",
        ["spellId"] = 13120,
        ["itemId"] = 10720,
        ["cooldown"] = 600,
        ["active"] = true
      }
    }
  }
end

--[[
  Find a spell by its spellId and optionally by a className. Knowing the className
  narrows the search down and thus speeds up the process but is not required.

  Note: Spells are only returned if they are also active. Inactive spells are ignored
  and will be returned even though they might be found in the spellmap.

  @param {string} normalizedSpellName
  @param {string} className
    Optional classname in english

  @return {table | nil}
    table - if a spell could be found
    nil - if no matching spell was found in the list
]]--
function me.FindSpell(normalizedSpellName, className)
  assert(type(normalizedSpellName) == "string",
    string.format("bad argument #1 to `FindSpell` (expected string got %s)", type(normalizedSpellName)))

  if className ~= nil then
    local className = strlower(className)
    if spellMap[className][normalizedSpellName] ~= nil and spellMap[className][normalizedSpellName].active then
      return spellMap[className][normalizedSpellName]
    end
  else
    for index, value in pairs(spellMap) do
        if spellMap[index][normalizedSpellName] ~= nil and spellMap[index][normalizedSpellName].active then
          return spellMap[index][normalizedSpellName]
        end
    end
  end

  return nil -- no spell found
end

--[[
  Get list for a certain category

  @param {string} category

  @return {table | nil}
    table - The category that was found in the list
    nil - if no category was found in the list
]]--
function me.GetAllForCategory(category)
  if not category then return nil end

  return spellMap[category]
end
