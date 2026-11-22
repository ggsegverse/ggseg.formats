# Moving the atlas object to S7 — what the spike found

Branch `explore/s7-object-system`, measured against `origin/main` (a17a2c3)
on S7 0.2.2 / R 4.6.1.

The spike rebuilt `ggseg_atlas` as an S7 class hierarchy and kept everything
else in the package unchanged, to find out what the ecosystem actually
notices.

## Result

| suite | pass | fail | error |
| --- | --- | --- | --- |
| ggseg.formats (this branch) | 1789 | 5 | 15 |
| ggseg | 742 | 0 | 0 |
| ggseg3d | 747 | 0 | 3 |
| ggseg.extra | 3602 | 0 | 1 |

Six installed atlas packages still shipping **S3 list** atlases
(ggsegSchaefer, ggsegHO, ggsegJHU, ggsegMelbourne, ggsegThalamus,
ggsegYeo2011) load, validate, type and plot unchanged against the S7
`ggseg.formats`. No atlas package has to be rebuilt, so the two
representations can coexist and the migration does not have to be a flag day.

## What the class hierarchy buys

`atlas_types()`, `atlas_parent_type()` and `atlas_class()` were a string
vocabulary, a `switch()` naming one parent, and a function pasting a class
vector together. They become the hierarchy itself:

```
ggseg_atlas (abstract)
├── cortical_atlas
├── subcortical_atlas
│   └── wm_atlas
├── tract_atlas
└── cerebellar_atlas
```

`type` is a read-only property computed from the class. The three coupled
places `set_atlas_type()` documents -- the `type` field, the `<type>_atlas`
class, the `ggseg_data_<type>` payload class -- can no longer disagree,
because only one of them is stored. The abstract parent cannot be
instantiated, so "the type vocabulary is closed" stops being a `match.arg()`
and a doc paragraph and becomes a property of the object system.

`$<-` routes to property assignment, so it validates. A core table with
duplicated labels assigned through `atlas$core <-` is now an error where the
list accepted it in silence.

## What it costs

### Invalid atlases become unconstructible — 15 of the 24 failures, and every single downstream one

Eleven tests here, three in ggseg3d and the one in ggseg.extra exist to check
what happens when an atlas is malformed: a duplicated label, a missing core
column, an unnamed palette, a payload that disagrees with the type. None of
them can build their fixture any more.

Every failure outside this package has this one cause. Nothing in ggseg,
ggseg3d or ggseg.extra broke because the atlas stopped being a list.

This is not a test problem to paper over. It means `assert_ggseg_atlas()`,
`validate_ggseg_atlas()` and `is_ggseg_atlas()` can only ever fire for a
legacy list atlas, and ggseg3d's defensive de-duplication only ever runs for
one. Both still matter -- the published atlases that carry alias rows are
exactly the legacy ones -- so the fixtures have to be rebuilt as legacy lists,
and the fact that they are testing the legacy path should be said out loud.

### Serialized atlases freeze their class definition

An S7 object carries a full copy of its class, constructor and validator.
Compressed, that is small: `R/sysdata.rda` grew 12.5 KB for four atlases, and
`dk()` alone costs +1.7 KB. The problem is not size.

Measured on a schema change of the kind this package makes regularly -- a new
required property plus a stricter validator -- an atlas built against the old
definition:

| | behaviour |
| --- | --- |
| accessing the new property | hard error, `Can't find property` |
| `validate()` | **passes**, against the stale embedded validator |
| property assignment | allowed; the new validator never runs |
| method dispatch | works, so the breakage is invisible until a property is touched |

With ~150 atlas objects across 32 packages built at different times on
r-universe, every schema change leaves a fleet of objects that look valid and
dispatch correctly. `atlas_structure_defect()` already defuses the validation
half by re-running the current constructor over the parts of an atlas, and it
should stay that way. The missing-property half has no such defence: it needs
a version stamp in `provenance` and a read path that refuses, or upgrades, an
atlas built against an older schema.

### Things that have to be done a particular way

- An S7 class defined in a package is tagged only with its **qualified** name,
  so `inherits(x, "cortical_atlas")` is `FALSE`. The unqualified tags are
  appended to the class vector. Appending, not prepending: S7 resolves methods
  for base generics through `class(x)[1]`, and a leading unqualified tag makes
  that lookup miss, so `atlas$core <- value` falls through to S7's "can't set
  properties with `$`".
- `print()`, `plot()`, `as.list()` and `as.data.frame()` have to be S7
  methods. `S7_object` outranks the appended tags, so the S3 methods were
  shadowed and `print(aseg())` dumped every property of the atlas to the
  console. They stay registered as S3 methods too, for legacy list atlases.
- There is no unvalidated low-level constructor. `restamp_class()` used
  `new_ggseg_atlas()` as a bare `structure()` call to re-stamp a legacy atlas
  whose `$data` was a raw sf frame; it now has to wrap that geometry in the
  payload class for its type.
- `names()` has to keep reporting `type`, computed or not. Leaving it out made
  `guess_type()` decide every atlas was untyped, and it answered
  `"subcortical"` for a cerebellar atlas, silently.
- A validator spanning two properties makes stepwise assignment impossible:
  `atlas$core <- x` fails on its own if the palette it is about to be paired
  with has not been assigned yet. Multi-slot edits must go through
  `S7::props(atlas) <- list(...)`.
- Property declaration order is not preserved; S7 reports computed properties
  last, so `names()` and the print header reorder.
- The rich constructor and the validator have to be kept in step by hand. An
  S7 validator can only return a string, so the cli bullets, the condition
  classes (`ggseg.formats_duplicate_labels`) and the warning-level schema
  nudges all stay in `ggseg_atlas()`. The validator carries a plain-string
  subset of the same checks. A check added to one is not enforced by the
  other until it is added there too.

### Dependency

`S7` becomes the fifth Import of the package the whole ecosystem depends on,
and it is 0.2.2 -- pre-1.0, by the R Consortium OOP working group, explicitly
intended to become a successor to S3 and S4 and to land in base R, but not
there yet. It has no dependencies of its own beyond `utils` and needs only
R >= 3.5.0.

## Not addressed by this spike

- The ~690 `$` reads in this package's tests and the ~150 in `data-raw`
  across the atlas packages were not touched; they keep working through the
  `$` shim.
- The vignettes that teach the `$` interface still run, but "Anatomy of an
  atlas" describes a list and would need rewriting around properties.
- `prepare_brain_meshes()` in ggseg3d still fakes two-argument dispatch with
  four single-dispatch S3 methods. Converting it to real S7 multiple dispatch
  on `(atlas, mesh_space)` is the one place multiple dispatch would pay, and
  it is independent of this change.
