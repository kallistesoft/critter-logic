import 'package:flutter/material.dart';

import 'worlds/world.dart';

// The equipped World's palette (see [WorldPalette] for what each color is for). Getters, so every screen follows
// the World the player picked; widgets shown in a preview of another World read `worldOf(context)` instead.
WorldPalette get _p => activeWorld.palette;

Color get background => _p.background;
Color get surface => _p.surface;
Color get ink => _p.ink;
Color get inkSoft => _p.inkSoft;
Color get accent => _p.accent;
Color get good => _p.good;
Color get bad => _p.bad;
Color get gold => _p.gold;

/// Sky and grass.
Color get skyTop => _p.skyTop;
Color get skyMid => _p.skyMid;
Color get skyLow => _p.skyLow;
Color get hillFar => _p.hillFar;
Color get hillMid => _p.hillMid;
Color get grass => _p.grass;
Color get grassDark => _p.grassDark;
Color get soil => _p.soil;

/// Wood and paper.
Color get wood => _p.wood;
Color get woodLight => _p.woodLight;
Color get woodDark => _p.woodDark;
Color get woodEdge => _p.woodEdge;
Color get paper => _p.paper;
Color get paperEdge => _p.paperEdge;

/// Text on wood panels.
Color get onWood => _p.onWood;
Color get onWoodSoft => _p.onWoodSoft;

/// Candy button colors (face, edge).
Color get leaf => _p.leaf;
Color get leafEdge => _p.leafEdge;
Color get sky => _p.sky;
Color get skyEdge => _p.skyEdge;
Color get goldEdge => _p.goldEdge;
Color get coral => _p.coral;
Color get coralEdge => _p.coralEdge;
Color get woodButton => _p.woodButton;

/// Nests zone colors, by zone id (up to 10 zones).
List<Color> get zoneColors => activeWorld.board.zones;

/// Pairs symbol colors.
Color get sunColor => _p.sunColor;
Color get moonColor => _p.moonColor;

/// Soft tints used around the UI.
Color get accentSoft => _p.accentSoft;
Color get goodSoft => _p.goodSoft;
Color get goldSoft => _p.goldSoft;
Color get rareBlue => _p.rareBlue;
Color get rareSoft => _p.rareSoft;
Color get tileEmpty => _p.tileEmpty;
Color get tileGiven => _p.tileGiven;
Color get shadow => _p.shadow;

/// Rounded corners of cards and buttons.
double get radius => activeWorld.radius;

/// The World's display font (Fredoka in the Meadow) for titles, numbers and buttons.
String get displayFont => activeWorld.font;
