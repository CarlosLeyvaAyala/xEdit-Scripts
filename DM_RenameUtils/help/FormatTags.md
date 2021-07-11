
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=3 orderedList=false} -->

<!-- code_chunk_output -->

- [Auto processing](#auto-processing)
  - [About format identifiers](#about-format-identifiers)
  - [About tags](#about-tags)
- [The `_Names.ini` file](#the-_namesini-file)
- [List of format identifiers](#list-of-format-identifiers)
    - [Leyends](#leyends)
  - [\*All](#all)
  - [Spell](#spell)
  - [Spellbook](#spellbook)

<!-- /code_chunk_output -->

# Auto processing
You can define your totally custom format by rewriting values in the `_Formats.ini` file.

`Formats` are the rules used to automatically rename things. Think about them as templates.

***Format identifiers and tags are case sensitive***.

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

***Tags are case sensitive***. If some tag isn't getting translated, first thing to check is if it's properly cased.

See examples below to understand all of this.

# The `_Names.ini` file
Here are defined tags that will be replaced by whatever you want.
It's just another layer of customization.

Let's suppose this script has found some spell belongs to the school of Alteration.
By default, the `[SpellSchool]` tag would output `Alt` because that's how it was defined in `_Names.ini` by me.
If you would open that file and change it to:

```
[SpellSchoolAlteration]=Alteration, motherfucker! Do you speak it!?
```

Then the `[SpellSchool]` tag would output `Alteration, motherfucker! Do you speak it!?` whenever it finds a spell from the Alteration school.

Tags using this functionality are marked as *Translated*.

# List of format identifiers
All examples were made using default values defined in [_Names.ini](the-_namesini-file), using this actual script.

### Leyends
- [x] This tag has been fully implemented.
- [ ] This tag has not been implemented, but it's planned to be.



## \*All
These tags are available for all format identifiers.

Master ESP tags:
- **[OriginalName]** Name of the record as defined in the first esp that creates it.

Current ESP tags:

- **[Name]** Name of the record as defined in the currently selected esp file.


## Spell
Available for records of Spell type. Signature `SPEL`.

Winning ESP tags:
- [x] **[MagicFxName]** Name of the magic effect associated with this spell.
- [x] **[SpellLvl]** Raw value of the Minimum Skill Level as defined in the esp. Usually `0`, `25`, `50`, `75` or `100`.
- [x] **[SpellSchool]** Name of the magic school this spell belongs to. *Translated*.
- [x] **[SpellLvlName]** Level of the spell as a name. Usually `Novice`, `Apprentice`, `Adept`, `Expert`, `Master`. *Translated*.
- [x] **[SpellLvlNum]** Number assigned to this school level. *Translated*.

#### Usage example

Format|Original|Processed
|---|---|---|
 `Spell=[SpellSchool] ([SpellLvlName]) - [OriginalName]` | Flames | Des (Novice) - Flames
 ^ | Detect Dead | Alt (Expert) - Detect Dead
 ^ | Mayhem | Ill (Master) - Mayhem
 `Spell=[SpellSchool] [SpellLvlNum]: [OriginalName] (min lvl: [SpellLvl])` | Flames | Des I: Flames (min lvl: 0)
^| Detect Dead | Alt IV: Detect Dead (min lvl: 75)
^|Mayhem|Ill V: Mayhem (min lvl: 100)

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

Format|Original|Processed
|---|---|---|
 `Spellbook=Tome, [Spell]` | Spell Tome: Firebolt| Tome, Des II: Firebolt
 ^ | Spell Tome: Ash Rune| Tome, Alt IV: Ash Rune
 `Spellbook=[[SpellSchool]] Spellbook ([SpellLvlName]): [SpellOriginalName]` | Spell Tome: Firebolt| [Des] Spellbook (Apprentice): Firebolt
 ^ | Spell Tome: Ash Rune| [Alt] Spellbook (Expert): Ash Rune

## WeaponMagical
- [ ] [EnchantName]

*[Translated]: This value is automatically translated from whatever you defined in `_Names.ini`.
*[Winning ESP]: Values are taken from the winning esp instead of the currently selected. Thus, making renaming compatible with patches already present in your load order.
*[Current ESP]: Values are strictly gotten from the esp the script is run on.
*[Master ESP]: Values are strictly gotten from the first esp that creates this record.
