---
title: "Chapitre 3 - Système de génération"
weight: 4
date: 2021-05-12 12:49:00
description: "Chapitre 3 - Le système de génération de Ziglang en détail."
---

# Modes de compilation  

Zig propose quatre modes de compilation, le mode debug étant le mode par défaut car il produit les temps de compilation les plus courts.

|               | Sécurité d'exécution | Optimizations |
|---------------|----------------------|---------------|
| Débogage      | Oui                  | Non           | 
| ReleaseSafe   | Oui                  | Oui, Vitesse  |
| ReleaseSmall  | Non                  | Oui, Taille   |
| ReleaseFast   | Non                  | Oui, Speed    |

Ces options peuvent être activées dans `zig run` et `zig test` avec les arguments `-O ReleaseSafe`, `-O ReleaseSmall` et `-O ReleaseFast`.

Il est recommandé aux utilisateurs de développer leurs logiciels avec la sécurité d'exécution activée, malgré le léger désavantage en termes de vitesse.

# Création d'un exécutable

Les commandes `zig build-exe`, `zig build-lib`, et `zig build-obj` peuvent être utilisées pour produire des exécutables, des bibliothèques et des objets, respectivement. Ces commandes prennent en compte un fichier source et des arguments.

Quelques arguments courants :
- `-fsingle-threaded`, qui affirme que le binaire est à thread unique. Cela transformera les mesures de sécurité des threads telles que les mutex en non-opérations.
- `-fstrip`, qui supprime les informations de débogage du binaire.
- `--dynamic`, qui est utilisé en conjonction avec `zig build-lib` pour produire une bibliothèque dynamique/partagée.

Créons un petit hello world. Sauvegardez-le sous le nom de `tiny-hello.zig`, et lancez `zig build-exe .\tiny-hello.zig -O ReleaseSmall -fstrip -fsingle-threaded`. Actuellement, pour `x86_64-windows`, cela produit un exécutable de 2.5KiB.

<!--no_test-->
```zig
const std = @import("std");

pub fn main() void {
    std.io.getStdOut().writeAll(
        "Hello World!",
    ) catch unreachable;
}
```

# Compilation croisée

Par défaut, Zig compile pour votre combinaison de CPU et de système d'exploitation. Ceci peut être surchargé par `-target`. Compilons notre tiny hello world pour une plateforme linux arm 64 bit.

`zig build-exe .\tiny-hello.zig -O ReleaseSmall -fstrip -fsingle-threaded -target aarch64-linux`

[QEMU](https://www.qemu.org/) ou similaire peut être utilisé pour tester facilement des exécutables conçus pour des plates-formes étrangères.

Quelques architectures CPU pour lesquelles vous pouvez effectuer une compilation croisée :
- `x86_64`
- `arm`
- `aarch64`
- `i386`
- `riscv64`
- `wasm32`

Quelques systèmes d'exploitation pour lesquels vous pouvez effectuer une compilation croisée :
- `linux`
- `macos`
- `windows`
- `freebsd`
- `netbsd`
- `dragonfly`
- `UEFI`

De nombreuses autres cibles sont disponibles pour la compilation, mais ne sont pas encore aussi bien testées. Voir [Zig's support table](https://ziglang.org/learn/overview/#wide-range-of-targets-supported) pour plus d'informations ; la liste des cibles testées s'allonge lentement.

Comme Zig compile par défaut pour votre processeur spécifique, ces binaires peuvent ne pas fonctionner sur d'autres ordinateurs avec des architectures de processeurs légèrement différentes. Il peut être utile de spécifier un modèle de CPU de base spécifique pour une meilleure compatibilité. Remarque : le choix d'une architecture de processeur plus ancienne permet une meilleure compatibilité, mais vous prive également des nouvelles instructions du processeur ; il s'agit d'un compromis efficacité/vitesse/compatibilité.

Compilons un binaire pour un processeur sandybridge (Intel x86_64, circa 2011), afin d'être raisonnablement sûr que quelqu'un avec un processeur x86_64 puisse exécuter notre binaire. Ici, nous pouvons utiliser `native` à la place de notre CPU ou OS, pour utiliser celui de notre système.

`zig build-exe .\tiny-hello.zig -target x86_64-native -mcpu sandybridge`

Les détails sur les architectures, OS, CPUs et ABIs (détails sur les ABIs dans le chapitre suivant) disponibles peuvent être trouvés en lançant `zig targets`. Note : la sortie est longue, et vous pouvez la diriger vers un fichier, par exemple `zig targets > targets.json`.

# Zig Build

La commande `zig build` permet aux utilisateurs de compiler en se basant sur un fichier `build.zig`. `zig init-exe` et `zig init-lib` peuvent être utilisés pour vous donner un projet de base.

Utilisons `zig init-exe` dans un nouveau dossier. Voici ce que vous trouverez.
```
.
├── build.zig
└── src
    └── main.zig
```
`build.zig` contient notre script de construction. Le *programme de construction* utilisera cette fonction `pub fn build` comme point d'entrée - c'est ce qui est exécuté quand vous lancez `zig build`.

<!--no_test-->
```zig
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "init-exe",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
```

`main.zig` contient le point d'entrée de notre exécutable.

<!--no_test-->
```zig
const std = @import("std");

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});
}
```

En utilisant la commande `zig build`, l'exécutable apparaîtra dans le chemin d'installation. Ici, nous n'avons pas spécifié de chemin d'installation, donc l'exécutable sera sauvegardé dans `./zig-out/bin`.

# Builder

Le type [`std.Build`](https://ziglang.org/documentation/master/std/#A;std:Build) de Zig contient les informations utilisées par le programme de construction. Cela inclut des informations telles que :

- la cible de construction
- le mode de publication
- l'emplacement des bibliothèques
- le chemin d'installation
- les étapes de construction

# CompileStep

Le type `std.build.CompileStep` contient les informations nécessaires à la construction d'une bibliothèque, d'un exécutable, d'un objet ou d'un test.

Utilisons notre `Builder` et créons une `CompileStep` en utilisant `Builder.addExecutable`, qui prend un nom et un chemin vers la racine du source.

<!--no_test-->
```zig
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const exe = b.addExecutable(.{
        .name = "init-exe",
        .root_source_file = .{ .path = "src/main.zig" },
    });
    b.installArtifact(exe);
}
```

# Modules

Le système de construction Zig utilise le concept de module, qui sont d'autres fichiers sources écrits en Zig. Utilisons un module.

Depuis un nouveau dossier, exécutez les commandes suivantes.
```
zig init-exe
mkdir libs
cd libs
git clone https://github.com/Sobeston/table-helper.git
```

Votre structure de répertoire devrait être la suivante.

```
.
├── build.zig
├── libs
│   └── table-helper
│       ├── example-test.zig
│       ├── README.md
│       ├── table-helper.zig
│       └── zig.mod
└── src
    └── main.zig
```

Dans votre nouveau `build.zig`, ajoutez les lignes suivantes.

<!--no_test-->
```zig
    const table_helper = b.addModule("table-helper", .{
        .source_file = .{ .path = "libs/table-helper/table-helper.zig" }
    });
    exe.addModule("table-helper", table_helper);
```

Maintenant, lorsqu'il est exécuté via `zig build`, [`@import`](https://ziglang.org/documentation/master/#import) à l'intérieur de votre `main.zig` fonctionnera avec la chaîne "table-helper". Cela signifie que main possède le paquet table-helper. Les paquets (type [`std.build.Pkg`](https://ziglang.org/documentation/master/std/#std;build.Pkg)) ont aussi un champ pour les dépendances de type ` ?[]const Pkg`, qui est mis par défaut à null. Cela vous permet d'avoir des paquets qui dépendent d'autres paquets. 

Placez ce qui suit dans votre `main.zig` et exécutez `zig build run`. 

<!--no_test-->
```zig
const std = @import("std");
const Table = @import("table-helper").Table;

pub fn main() !void {
    try std.io.getStdOut().writer().print("{}\n", .{
        Table(&[_][]const u8{ "Version", "Date" }){
            .data = &[_][2][]const u8{
                .{ "0.7.1", "2020-12-13" },
                .{ "0.7.0", "2020-11-08" },
                .{ "0.6.0", "2020-04-13" },
                .{ "0.5.0", "2019-09-30" },
            },
        },
    });
}
```

Ce tableau devrait s'afficher dans la console.

```
Version Date       
------- ---------- 
0.7.1   2020-12-13 
0.7.0   2020-11-08 
0.6.0   2020-04-13 
0.5.0   2019-09-30 
```


Zig n'a pas encore de gestionnaire de paquets officiel. Quelques gestionnaires de paquets expérimentaux non officiels existent cependant, à savoir [gyro](https://github.com/mattnite/gyro) et [zigmod](https://github.com/nektro/zigmod). Le paquet `table-helper` est conçu pour les supporter tous les deux.

Voici quelques bons endroits où trouver des paquets : [astrolabe.pm](https://astrolabe.pm), [zpm](https://zpm.random-projects.net/), [awesome-zig](https://github.com/nrdmn/awesome-zig/), et le [tag zig sur GitHub](https://github.com/topics/zig).

# Étapes de construction

Les étapes de construction sont un moyen de fournir des tâches à exécuter par le programme de construction. Créons une étape de construction, et faisons-en la valeur par défaut. Lorsque vous lancez `zig build`, cela produira `Hello!`. 

<!--no_test-->
```zig
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const step = b.step("task", "do something");
    step.makeFn = myTask;
    b.default_step = step;
}

fn myTask(self: *std.build.Step, progress: *std.Progress.Node) !void {
    std.debug.print("Hello!\n", .{});
    _ = progress;
    _ = self;
}
```

Nous avons appelé `b.installArtifact(exe)` plus tôt - cela ajoute une étape de construction qui dit au constructeur de construire l'exécutable.

# Générer de la documentation

Le compilateur Zig est livré avec une génération automatique de documentation. Celle-ci peut être invoquée en ajoutant `-femit-docs` à votre commande `zig build-{exe, lib, obj}` ou `zig run`. Cette documentation est sauvegardée dans `./docs`, comme un petit site web statique.

La génération de documentation de Zig utilise des *doc comments* qui sont similaires aux commentaires, en utilisant `///` au lieu de `//`, et en précédant les globales.

Ici, nous allons sauvegarder ce fichier sous le nom de `x.zig` et construire la documentation avec `zig build-lib -femit-docs x.zig -target native-windows`. Il y a certaines choses à retenir ici :
- Seules les choses qui sont publiques avec un commentaire de doc apparaîtront
- Les commentaires de docs vides peuvent être utilisés
- Les commentaires de doc peuvent utiliser un sous-ensemble de markdown
- Les éléments n'apparaîtront dans la documentation générée que si le compilateur les analyse ; vous devrez peut-être forcer l'analyse pour que les éléments apparaissent.

<!--no_test-->
```zig
const std = @import("std");
const w = std.os.windows;

///**Opens a process**, giving you a handle to it. 
///[MSDN](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openprocess)
pub extern "kernel32" fn OpenProcess(
    ///[The desired process access rights](https://docs.microsoft.com/en-us/windows/win32/procthread/process-security-and-access-rights)
    dwDesiredAccess: w.DWORD,
    ///
    bInheritHandle: w.BOOL,
    dwProcessId: w.DWORD,
) callconv(w.WINAPI) ?w.HANDLE;

///spreadsheet position
pub const Pos = struct{
    ///row
    x: u32,
    ///column
    y: u32,
};

pub const message = "hello!";

//used to force analysis, as these things aren't otherwise referenced.
comptime {
    _ = OpenProcess;
    _ = Pos;
    _ = message;
}

//Alternate method to force analysis of everything automatically, but only in a test build:
test "Force analysis" {
    comptime {
        std.testing.refAllDecls(@This());
    }
}
```

Lorsqu'on utilise un `build.zig`, on peut l'invoquer en fixant le champ `emit_docs` à `.emit` sur une `CompileStep`. Nous pouvons créer une étape de compilation pour générer des documents comme suit et l'invoquer avec `$ zig build docs`.

<!--no_test-->
```zig
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("x", "src/x.zig");
    lib.setBuildMode(mode);
    lib.install();

    const tests = b.addTest("src/x.zig");
    tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&tests.step);

    //Build step to generate docs:
    const docs = b.addTest("src/x.zig");
    docs.setBuildMode(mode);
    docs.emit_docs = .emit;
    
    const docs_step = b.step("docs", "Generate docs");
    docs_step.dependOn(&docs.step);
}
```

Cette génération est expérimentale et échoue souvent avec des exemples complexes. Elle est utilisée par la [documentation de la bibliothèque standard](https://ziglang.org/documentation/master/std/).

Lors de la fusion de jeux d'erreurs, les chaînes de documentation du jeu d'erreurs le plus à gauche sont prioritaires sur celles de droite. Dans ce cas, le commentaire de la doc pour `C.PathNotFound` est le commentaire de la doc fourni dans `A`.

<!--no_test-->
```zig
const A = error{
    NotDir,

    /// A doc comment
    PathNotFound,
};
const B = error{
    OutOfMemory,

    /// B doc comment
    PathNotFound,
};

const C = A || B;
```

# Fin du chapitre 3

Ce chapitre est incomplet. Dans le futur, il contiendra des utilisations avancées de `zig build`.

Les commentaires et les PRs sont les bienvenus.
