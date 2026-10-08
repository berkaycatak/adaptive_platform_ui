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
| @DFelten | Fixed toolbar showing the wrong tab's bar while a route is dragged back, with `IndexedStack` tabs | #164 |
| @Anderzzon | Found the semantics assertion when a back swipe is reversed under the fixed toolbar, and traced it to `FadeTransition` dropping semantics at zero opacity | #166, fixed in #170 |

### Under review

| Who | What | Where |
|---|---|---|
| @primer03, @DFelten | Taps not reaching the iOS 26 native tab bar; two approaches, one to pick | #141, #162 |
| @bryandelgado99 | Android build tooling update, stops applying the Kotlin Gradle Plugin from the plugin | #160 |
| @luflow | Radio drawn as a ring with an inner dot | #154 |
| @luflow | `borderColor` and `borderWidth` on `AdaptiveCard` | #153 |
| @luflow | Example app on the UIScene lifecycle | #151 |
| @luflow, @DFelten | Native menus on app bar actions; two overlapping PRs | #149, #163 |
| @itsatifsiddiqui | Native Liquid Glass context menu on iOS 26+ | #161 |
| @gem85247 | `selected` on `AdaptivePopupMenuItem` | #147 |
| @KhalidSaud | Tab bar direction consistent across selection states | #140 |
| @terrykang90 | Customizable iOS 26 badge on the tab bar | #127 |
| @Qian-Samuel | Alert dialog tint from `CupertinoTheme.primaryColor` | #121 |
| @matteo-teodori | Modal canvas clipping and alert dialog navigation | #131 |
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
