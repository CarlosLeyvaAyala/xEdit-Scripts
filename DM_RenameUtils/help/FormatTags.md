<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=3 orderedList=false} -->

<!-- code_chunk_output -->

- [Auto processing](#auto-processing)
  - [About format identifiers](#about-format-identifiers)
  - [About tags](#about-tags)
- [The `_Names.txt` file](#the-_namestxt-file)
- [List of format identifiers](#list-of-format-identifiers)
    - [Leyends](#leyends)
  - [\*All](#all)
  - [Spell](#spell)
  - [Spellbook](#spellbook)
  - [Weapon](#weapon)
  - [WeaponMagical](#weaponmagical)

<!-- /code_chunk_output -->

# Auto processing

You can define your totally custom format by rewriting values in the `_Formats.ini` file.

`Formats` are the rules used to automatically rename things. Think about them as templates.

**_Format identifiers and tags are case sensitive_**.

## About format identifiers

The first word in each line says on whom the format will be applied to.
Whatever it is after the `=` sign says what the final name for the record will be.

For example, if a line starts with `Spellbook=`, whatever lays after it will be used to rename spell teaching books.

You can only have one unique format identifier per file.
If you add two lines starting with `Spell=`, only one of them will be used to rename things... or maybe both, who knows... just expect things to go wrong.

**Invalid format identifiers are just ignored by the script**.
This way, you can make interesting things, like having many different formats for things, but invalidating those you don't want to use right now. For example:

```
Spell=Valid spell format
-Spell=Invalid spell format
```

`-Spell=` is invalid, but can be toggled it by doing this:

```
-Spell=Not valid anymore
Spell=This will now be used
```

## About tags

You can write whatever you want after the `=` sign, but only valid tags will be replaced in your text.
All tags are enclosed between square brackets `[like this]` and are predefined by this script.

Tags are asociated to variable values found on the record being processed and you can use them to automatically rename a record based on its actual data.
For example, the `[SpellSchool]` tag carries which is the magica school of the record currently being renamed.

Some tags are available to all format identifiers, others are available for many, and others are exclusive to only one format identifier.
If you think about it, books don't get classified as `Light/Heavy/Clothing`, but armors do.

**_Tags are case sensitive_**. If some tag isn't getting translated, first thing to check is if it's properly cased.

See examples below to understand all of this.

# The `_Names.txt` file

Here are defined tags that will be replaced by whatever you want.
It's just another layer of customization.

Let's suppose this script has found some spell belongs to the school of Alteration.
By default, the `[SpellSchool]` tag would output `Alt` because that's how it was defined in `_Names.txt` by me.
If you would open that file and change it to:

```
[SpellSchoolAlteration]=Alteration, motherfucker! Do you speak it!?
```

Then the `[SpellSchool]` tag would output `Alteration, motherfucker! Do you speak it!?` whenever it finds a spell from the Alteration school.

Tags using this functionality are marked as _Translated_.

# List of format identifiers

All examples were made using default values defined in [\_Names.txt](the-_namesini-file), using this actual script.

### Leyends

- [x] This tag has been fully implemented.
- [ ] This tag has not been implemented, but it's planned to be.

## \*All

These tags are available for all format identifiers.

Master ESP tags:

- **[OriginalName]** Name of the record as defined in the first esp that creates it.

Current ESP tags:

- **[Name]** Name of the record as defined in the currently selected esp file.
- **[EDID]** Editor ID.

## Spell

Available for records of Spell type. Signature `SPEL`.

Winning ESP tags:

- [x] **[MagicFxName]** Name of the magic effect associated with this spell.
- [x] **[SpellLvl]** Raw value of the Minimum Skill Level as defined in the esp. Usually `0`, `25`, `50`, `75` or `100`.
- [x] **[SpellSchool]** Name of the magic school this spell belongs to. _Translated_.
- [x] **[SpellLvlName]** Level of the spell as a name. Usually `Novice`, `Apprentice`, `Adept`, `Expert`, `Master`. _Translated_.
- [x] **[SpellLvlNum]** Number assigned to this school level. _Translated_.

#### Usage example

| Format                                                                    | Original    | Processed                         |
| ------------------------------------------------------------------------- | ----------- | --------------------------------- |
| `Spell=[SpellSchool] ([SpellLvlName]) - [OriginalName]`                   | Flames      | Des (Novice) - Flames             |
| ^                                                                         | Detect Dead | Alt (Expert) - Detect Dead        |
| ^                                                                         | Mayhem      | Ill (Master) - Mayhem             |
| `Spell=[SpellSchool] [SpellLvlNum]: [OriginalName] (min lvl: [SpellLvl])` | Flames      | Des I: Flames (min lvl: 0)        |
| ^                                                                         | Detect Dead | Alt IV: Detect Dead (min lvl: 75) |
| ^                                                                         | Mayhem      | Ill V: Mayhem (min lvl: 100)      |

## Spellbook

Available for records of Book type **that teach spells**. Signature `BOOK`.

`Spellbook` has available to it all tags [Spell](#Spell) has access to, plus the following tags.

Master ESP tags:

- [x] **[SpellOriginalName]** Name of the spell as defined in the first esp that creates it.

Current ESP tags:

- [x] **[SpellName]** Name of the spell as defined in the currently selected esp file.

Winning ESP tags:

- [x] **[Spell]** Spell name generated by the [Spell](#Spell) format.

#### Usage example

| Format                                                                      | Original             | Processed                              |
| --------------------------------------------------------------------------- | -------------------- | -------------------------------------- |
| `Spellbook=Tome, [Spell]`                                                   | Spell Tome: Firebolt | Tome, Des II: Firebolt                 |
| ^                                                                           | Spell Tome: Ash Rune | Tome, Alt IV: Ash Rune                 |
| `Spellbook=[[SpellSchool]] Spellbook ([SpellLvlName]): [SpellOriginalName]` | Spell Tome: Firebolt | [Des] Spellbook (Apprentice): Firebolt |
| ^                                                                           | Spell Tome: Ash Rune | [Alt] Spellbook (Expert): Ash Rune     |

## Weapon

Master ESP tags:

- [x] **[WeaponShortName]** Original name without weapon type. See long explanation below.
- [x] **[WeaponType]** Gotten from the weapon keywords. If no type is found or it's wrong, it means the weapon has no proper keywords. _Translated_.

#### WeaponShortName

This may need some extra configuration to properly work.

The idea for this tag is to remove the weapon type from the name, but some weapon mods (like Heavy Armory) have new names that aren't vanilla (like "trident") but the weapons themselves are vanilla for all intents and purposes.

In that case, the best way to get the item name without the weapon type is to outright delete it from the name **based on a list of known weapon type names**.

That list is named `_Clean_Weapon.txt` and there you can add/delete words (or phrases) you want to get removed from a weapon name.

Names in that list are case sensitive and there by default I added all vanilla names.

As you can notice, there are some variants of the same word I've found while renaming weapons in real life, like:

- Battle Axe
- Battleaxe
- War Axe
- Waraxe

If you find some inconsistent names like those while renaming your mods, you can add them to `_Clean_Weapon.txt` so your weapons are properly renamed.

***THIS IS NOT AN ALPHABETICALLY SORTED LIST***. If you sort it, you can get unexpected results.

Words in this list will be removed by their order of appearance.
In general, try to add longer words first and shorter words later (notice `Axe` location compared to `Battle Axe` and `War Axe`).

## WeaponMagical

Master ESP tags:

- [x] All [Weapon](#weapon) tags are available.
- [x] **[MagicWeaponUniqueName]** Everything after _"`of `"_.

Current ESP tags:

- [x] **[WeaponLvlNum]** Enchantment level gotten from the Editor ID of the weapon; specifically, the ending number in it, like the **`01`** in `EnchShSteelTridentSpearSoulTrap01`.
      Depending on the weapon, sometimes it's better to use **[SpellLvlNum]**. _Translated_.

Winning ESP tags:

- [x] **[EnchantName]** Name of the enchantment on this weapon.
- [x] All **[Spell](#spell)** tags are available to the weapon.
      If the weapon has an enchantment with multiple magic effects, only the first effect data is gotten.

#### WeaponShortName

Aside from all the behavior this tag has for unenchanted weapons, for enchanted ones it has an extra effect to keep in mind: **it removes EVERYTHING after _"of..."_**.

For example:

| Weapon name                                                  | [WeaponShortName] |
| ------------------------------------------------------------ | ----------------- |
| Nordic Battle Axe of Enervation                              | Nordic            |
| Elven Club of the Interstellar Pseudo Philosophical Bullshit | Elven Club        |
| Waraxe of Imperial Domination                                | _&lt;nothing&gt;_ |

Notice how in the last example `[WeaponShortName]` returns nothing because "Waraxe" would have been removed in the unenchanted version as well.

#### Usage example

| Format                                                                         | Editor ID                           | Original                                | Processed                                     |
| ------------------------------------------------------------------------------ | ----------------------------------- | --------------------------------------- | --------------------------------------------- |
| `WeaponMagical=[WeaponType]: [WeaponShortName] - [EnchantName] [WeaponLvlNum]` | \_SRE_EnchHonedSwordDunmer03        | Honed Ancient Nord Sword of Dunmer Bane | Sword: Honed Ancient Nord - Dunmer Killer III |
| `WeaponMagical=[WeaponType]: [WeaponShortName] - [EnchantName] [SpellLvlNum]`  | \_SRE_EnchHonedSwordDunmer03        | Honed Ancient Nord Sword of Dunmer Bane | Sword: Honed Ancient Nord - Dunmer Killer I   |
| `WeaponMagical=[MagicWeaponUniqueName] [WeaponType] of [SpellSchool]`          | \_SRE_EnchForswornSwordAbsorbSoul01 | Sword of Lost Souls                     | Lost Souls Sword of Destruction               |

*[Translated]: This value is automatically translated from whatever you defined in `_Names.txt`.
*[Winning ESP]: Values are taken from the winning esp instead of the currently selected. Thus, making renaming compatible with patches already present in your load order.
*[Current ESP]: Values are strictly gotten from the esp the script is run on.
*[Master ESP]: Values are strictly gotten from the first esp that creates this record.
