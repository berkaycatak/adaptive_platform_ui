# Contributors

Who did what, release by release, so that nobody is left out of the changelog
and the credits. Names are GitHub handles. The "Unreleased" section collects
everything merged since the last release and is folded into CHANGELOG.md when
the release is cut.

## Unreleased (1.0.2)

| Who | What | Where |
|---|---|---|
| @Danilo-Mota | Found and fixed `resizeToAvoidBottomInset` being ignored on the plain iOS page branch and in the drawer wrapper, with exact measurements | #158, #159 |
| @sergi-labhouse | iPhone Duo: vertical bar on the left in the leading Split View pane, via `UITraitCollection.verticalBarEdge`; the system reserves no strip there, so the host adds it | #169 |
| @luflow | Radio drawn as a ring with an inner dot; `borderColor` and `borderWidth` on `AdaptiveCard`; example app on the UIScene lifecycle | #154, #153, #151 |
| @goalbypro, @bryandelgado99 | Android JVM 17 target for the plugin module (report, and the fix taken from the larger tooling PR) | #119, #160 |
| @itsatifsiddiqui | Native Liquid Glass context menu on iOS 26+ | #161 |
| @DFelten | Native menus on app bar actions, in the fixed toolbar and the Duo capsule as well | #163 |
| @luflow | Section titles in menus on all three platforms; example app on Swift Package Manager | #149, #150 |
| @gem85247 | `selected` checkmark on popup menu items; child-mode button sizing fix | #147 |
| @KhalidSaud | Tab bar layout direction trait for the selected item | #140 |
| @terrykang90 | Badge text and colors on tab bar destinations, iOS 26 native plus Cupertino and Material | #127 |
| @Qian-Samuel | Alert dialog primary button tint from `CupertinoTheme.primaryColor` | #121 |
| @DFelten | Fixed toolbar showing the wrong tab's bar while a route is dragged back, with `IndexedStack` tabs | #164 |
| @Anderzzon | Found the semantics assertion when a back swipe is reversed under the fixed toolbar, and traced it to `FadeTransition` dropping semantics at zero opacity | #166, fixed in #170 |

### Held for 2.0

| Who | What | Where |
|---|---|---|
| @primer03, @DFelten | Taps not reaching the iOS 26 native tab bar; needs Flutter 3.47's gesture blocking policy | #141, #162 |
| @pento, @Crucialjun, @robert-virkus | Migration to `material_ui` / `cupertino_ui` (Flutter 3.47); three PRs for the same change | #145, #146, #168, #167 |

## 1.0.1

| Who | What | Where |
|---|---|---|
| Community reviewers on X | Pointed out that the iPhone Duo tab bar belonged in the vertical bar, and that content ran under it | 1.0.1 |

## 1.0.0

| Who | What | Where |
|---|---|---|
| @erkamyaman | Reported stale reserved regions after a hinge move in `foldable`, which the Duo bar depends on | foldable 1.0.2 |

## 0.1.111 and earlier

See CHANGELOG.md; credits are inline there.
