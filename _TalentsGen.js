#!/usr/bin/env node
/**
 * @File   : DataGen.js
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 5/21/2020, 10:31:02 PM
 */

const fs = require("fs");
const got = require("got");
const util = require("util");

const LOCALES = [
    [0, "enUS"],
    [1, "koKR"],
    [2, "frFR"],
    [3, "deDE"],
    [4, "zhCN"],
    [5],
    [6, "esES"],
    [7, "ruRU"],
    [8, "ptBR"],
    [9, "itIT"],
];

// const TALENTS = "https://classic.wowhead.com/data/talents-classic";
// const LOCALE = "https://wow.zamimg.com/js/locale/classic.enus.js";
const TALENTS = "https://%s.wowhead.com/data/talents-classic";
const LOCALE = "https://%s.wowhead.com/menus";
const GLOBAL = "https://%s.wowhead.com/data/global?locale=%d";

const BACKGROUNDS = {
    ["283"]: "DruidBalance",
    ["281"]: "DruidFeralCombat",
    ["282"]: "DruidRestoration",
    ["361"]: "HunterBeastMastery",
    ["363"]: "HunterMarksmanship",
    ["362"]: "HunterSurvival",
    ["81"]: "MageArcane",
    ["41"]: "MageFire",
    ["61"]: "MageFrost",
    ["382"]: "PaladinHoly",
    ["383"]: "PaladinProtection",
    ["381"]: "PaladinCombat",
    ["201"]: "PriestDiscipline",
    ["202"]: "PriestHoly",
    ["203"]: "PriestShadow",
    ["182"]: "RogueAssassination",
    ["181"]: "RogueCombat",
    ["183"]: "RogueSubtlety",
    ["261"]: "ShamanElementalCombat",
    ["263"]: "ShamanEnhancement",
    ["262"]: "ShamanRestoration",
    ["302"]: "WarlockCurses",
    ["303"]: "WarlockSummoning",
    ["301"]: "WarlockDestruction",
    ["161"]: "WarriorArms",
    ["164"]: "WarriorFury",
    ["163"]: "WarriorProtection",
};

function getTalentData(body) {
    const m = body.match(/WH\.Wow\.TalentCalcClassic\.data\s*=\s*({[^;]+});/);
    const data = JSON.parse(m[1]).talents;
    return data;
}

// function getClassTalents(body) {
//     const m = body.match(/var mn_spells=(.+);\(function/);

//     for (const item of eval(m[1])) {
//         if (item[1] === "Talents") {
//             return item[3]
//                 .map((t) => [t[1], t[3].map((r) => r[0])])
//                 .reduce((t, v) => {
//                     t[v[0]] = v[1];
//                     return t;
//                 }, {});
//         }
//     }
// }

function getClassTalents(body) {
    const m = body.match(/var mn_spells\s*=(.+);/);

    const d = eval(m[1]);
    const item = d[2][3];

    return Object.fromEntries(
        item.map(([clsId, clsName, , t]) => [clsName, t.map(([talentId]) => Number.parseInt(talentId))])
    );
}

// function getTalentLocales(body) {
//     const m = body.match(/var g_chr_specs=({[^;]+});/);
//     return JSON.parse(m[1]);
// }

function getTalentLocales(body) {
    const m = body.match(/WH\.Wow\.PlayerClass\.Specialization\.names', ([^;\)]+)/);

    return JSON.parse(m[1]);
}

async function genTalents(version, output, hasId) {
    const ClassTalents = getClassTalents((await got(util.format(LOCALE, version))).body);
    const Talents = getTalentData((await got(util.format(TALENTS, version))).body);
    const Locales = {};

    for (const [id, locale] of LOCALES) {
        if (locale) {
            Locales[locale] = getTalentLocales(
                // (await got(`https://wow.zamimg.com/js/locale/classic.${locale.toLowerCase()}.js`)).body
                (await got(util.format(GLOBAL, version, id))).body
            );
        }
    }

    console.log(`Generate ${version}`);

    const file = fs.createWriteStream(output);

    file.write(`-- GENERATE BY _TalentGen.js
select(2,...).TalentMake()`);

    const indexs = LOCALES.map(([, locale]) => (locale ? `'${locale}'` : "nil"));
    file.write(`D(${indexs})`);

    for (const [cls, tabIds] of Object.entries(ClassTalents)) {
        console.log(`For ${cls}`);

        file.write(`C'${cls.toUpperCase()}'`);

        for (const tabId of tabIds) {
            const talents = Object.values(Talents[tabId]).sort((a, b) => a.row * 10 + a.col - b.row * 10 - b.col);

            file.write(`T('${BACKGROUNDS[tabId]}',${talents.length})`);

            const names = LOCALES.map(([, locale]) => (locale ? `'${Locales[locale][tabId]}'` : "nil")).join(",");

            file.write(`N(${names})`);

            for (const talent of talents) {
                if (hasId) {
                    file.write(`I(${talent.row + 1},${talent.col + 1},${talent.ranks.length},${talent.id})`);
                } else {
                    file.write(`I(${talent.row + 1},${talent.col + 1},${talent.ranks.length})`);
                }
                file.write(`R{${talent.ranks.join(",")}}`);

                if (talent.requires) {
                    for (const req of talent.requires) {
                        const reqTalent = Talents[tabId][req.id];
                        const reqIndex = talents.indexOf(reqTalent) + 1;
                        file.write(`P(${reqTalent.row + 1},${reqTalent.col + 1},${reqIndex})`);
                    }
                }
            }
        }
    }
    file.end("", "utf-8");
}

async function main() {
    await genTalents("classic", "Data/Talents.lua", false);
    await genTalents("tbc", "Data/Talents.BCC.lua", true);
}

main();
