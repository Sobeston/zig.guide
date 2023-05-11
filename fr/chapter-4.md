---
title: "Chapitre 4 - Travailler avec C"
weight: 5
date: 2023-04-28 18:00:00
description: "Chapitre 4 - Découvrez comment le langage de programmation Zig utilise le code C. Ce tutoriel couvre les types de données C, la FFI, la construction avec C, translate-c et plus encore !"
---

Zig a été conçu dès le départ avec l'interopérabilité en C comme une fonctionnalité de premier ordre. Dans cette section, nous allons voir comment cela fonctionne.

# ABI

Une ABI *(application binary interface)* est un standard qui concerne :

- la disposition en mémoire des types (c'est-à-dire la taille d'un type, son alignement, ses décalages et la disposition de ses champs)
- le nommage des symboles dans l'éditeur (par exemple, la confusion des noms)
- les conventions d'appel des fonctions (c'est-à-dire la manière dont un appel de fonction fonctionne au niveau binaire).

En définissant ces règles et en ne les enfreignant pas, une ABI est dite stable et peut être utilisée, par exemple, pour lier de manière fiable plusieurs bibliothèques, exécutables ou objets qui ont été compilés séparément (potentiellement sur des machines différentes, ou en utilisant des compilateurs différents). Cela permet de mettre en place une FFI *(interface de fonction étrangère)*, qui permet de partager du code entre les langages de programmation.

Zig supporte nativement les ABI C pour les choses "externes" ; l'ABI C utilisée dépend de la cible pour laquelle vous compilez (par exemple, l'architecture du processeur, le système d'exploitation). Cela permet une interopérabilité presque sans faille avec du code qui n'a pas été écrit en Zig ; l'utilisation des ABIs C est standard parmi les langages de programmation.

Zig n'utilise pas d'ABI en interne, ce qui signifie que le code doit se conformer explicitement à une ABI C lorsqu'un comportement binaire reproductible et défini est nécessaire.

# Types primitifs C

Zig fournit des types spéciaux préfixés `c_` pour se conformer à l'ABI du C. Ceux-ci n'ont pas de taille fixe, mais changent de taille en fonction de l'ABI utilisée.

| Type         | C Équivalent      | Taille minimale (bits) |
|--------------|-------------------|------------------------|
| c_short      | short             | 16                     |
| c_ushort     | unsigned short    | 16                     |
| c_int        | int               | 16                     |
| c_uint       | unsigned int      | 16                     |
| c_long       | long              | 32                     |
| c_ulong      | unsigned long     | 32                     |
| c_longlong   | long long         | 64                     |
| c_ulonglong  | unsigned longlong | 64                     |
| c_longdouble | long double       | N/A                    |
| c_void       | void              | N/A                    |

Note : Le void de C (et le `c_void` de Zig) a une taille inconnue non nulle. Le `void` de Zig est un vrai type de taille zéro.

# Les conventions d'appel

Les conventions d'appel décrivent comment les fonctions sont appelées. Cela inclut la manière dont les arguments sont fournis à la fonction (c'est-à-dire où ils vont - dans les registres ou sur la pile, et comment), et comment la valeur de retour est reçue.

Dans Zig, l'attribut `callconv` peut être donné à une fonction. Les conventions d'appel disponibles peuvent être trouvées dans [std.builtin.CallingConvention](https://ziglang.org/documentation/master/std/#A;std:builtin.CallingConvention). Ici, nous utilisons la convention d'appel cdecl.```zig
```zig
fn add(a: u32, b: u32) callconv(.C) u32 {
    return a + b;
}
```

Marquer vos fonctions avec la convention d'appel du C est crucial lorsque vous appelez Zig depuis le C.

# Les structures externes

Les structures normales dans Zig n'ont pas de disposition définie ; les structures "externes" sont nécessaires lorsque vous voulez que la disposition de votre structure corresponde à la disposition de votre ABI C.

Créons une structure extern. Ce test doit être exécuté avec `x86_64` et une ABI `gnu`, ce qui peut être fait avec `-target x86_64-native-gnu`.

```zig
const expect = @import("std").testing.expect;

const Data = extern struct { a: i32, b: u8, c: f32, d: bool, e: bool };

test "hmm" {
    const x = Data{
        .a = 10005,
        .b = 42,
        .c = -10.5,
        .d = false,
        .e = true,
    };
    const z = @ptrCast([*]const u8, &x);

    try expect(@ptrCast(*const i32, z).* == 10005);
    try expect(@ptrCast(*const u8, z + 4).* == 42);
    try expect(@ptrCast(*const f32, z + 8).* == -10.5);
    try expect(@ptrCast(*const bool, z + 12).* == false);
    try expect(@ptrCast(*const bool, z + 13).* == true);
}
```

Voici à quoi ressemble la mémoire à l'intérieur de notre valeur `x`.

| Field | a  | a  | a  | a  | b  |    |    |    | c  | c  | c  | c  | d  | e  |    |    |
|-------|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|
| Bytes | 15 | 27 | 00 | 00 | 2A | 00 | 00 | 00 | 00 | 00 | 28 | C1 | 00 | 01 | 00 | 00 |

Notez qu'il y a des espaces au milieu et à la fin - c'est ce qu'on appelle le "padding". Les données de ce padding sont de la mémoire non définie, et ne seront pas toujours nulles.

Comme notre valeur `x` est celle d'une structure extern, nous pouvons la passer en toute sécurité à une fonction C qui attend une `Data`, à condition que la fonction C soit également compilée avec la même ABI `gnu` et le même arc de CPU.

# Alignement

Pour des raisons de circuits, les CPU accèdent aux valeurs primitives à certains multiples de la mémoire. Cela peut signifier par exemple que l'adresse d'une valeur `f32` doit être un multiple de 4, ce qui signifie que `f32` a un alignement de 4. Ce soi-disant "alignement naturel" des types de données primitives dépend de l'architecture du CPU. Tous les alignements sont des puissances de 2.

Les données d'un alignement plus grand ont également l'alignement de chaque alignement plus petit ; par exemple, une valeur qui a un alignement de 16 a également un alignement de 8, 4, 2 et 1.

Nous pouvons créer des données spécialement alignées en utilisant la propriété `align(x)`. Ici, nous créons des données avec un alignement plus grand.
```zig
const a1: u8 align(8) = 100;
const a2 align(8) = @as(u8, 100);
```
And making data with a lesser alignment. Note: Creating data of a lesser alignment isn't particularly useful.
```zig
const b1: u64 align(1) = 100;
const b2 align(1) = @as(u64, 100);
```

Comme `const`, `align` est aussi une propriété des pointeurs.
```zig
test "aligned pointers" {
    const a: u32 align(8) = 5;
    try expect(@TypeOf(&a) == *align(8) const u32);
}
```

Utilisons une fonction qui attend un pointeur aligné.

```zig
fn total(a: *align(64) const [64]u8) u32 {
    var sum: u32 = 0;
    for (a) |elem| sum += elem;
    return sum;
}

test "passing aligned data" {
    const x align(64) = [_]u8{10} ** 64;
    try expect(total(&x) == 640);
}
```

# Structures empaquetées

Par défaut, tous les champs de structure dans Zig sont naturellement alignés sur [`@alignOf(FieldType)`](https://ziglang.org/documentation/master/#alignOf) (la taille ABI), mais sans disposition définie. Parfois, vous pouvez vouloir avoir des champs de structure avec une disposition définie qui n'est pas conforme à votre ABI C. Les structures `packed` vous permettent d'avoir un contrôle extrêmement précis de vos champs de structure, vous permettant de placer vos champs sur une base de bit par bit.

Dans les structures empaquetées, les entiers de Zig prennent leur largeur de bit dans l'espace (par exemple, un `u12` a une [`@bitSizeOf`](https://ziglang.org/documentation/master/#bitSizeOf) de 12, ce qui signifie qu'il occupera 12 bits dans la structure empaquetée). Les bools prennent également 1 bit, ce qui signifie que vous pouvez facilement implémenter des drapeaux de bits.

```zig
const MovementState = packed struct {
    running: bool,
    crouching: bool,
    jumping: bool,
    in_air: bool,
};

test "packed struct size" {
    try expect(@sizeOf(MovementState) == 1);
    try expect(@bitSizeOf(MovementState) == 4);
    const state = MovementState{
        .running = true,
        .crouching = true,
        .jumping = true,
        .in_air = true,
    };
    _ = state;
}
```

Actuellement, les structures empaquetées de Zig présentent des bogues de compilateur de longue date et ne fonctionnent pas pour de nombreux cas d'utilisation.

# Pointeurs alignés sur un bit

Similaires aux pointeurs alignés, les pointeurs alignés sur les bits ont des informations supplémentaires dans leur type qui informent sur la manière d'accéder aux données. Ils sont nécessaires lorsque les données ne sont pas alignées sur un octet. L'information sur l'alignement des bits est souvent nécessaire pour adresser les champs à l'intérieur de structures compactes.

```zig
test "bit aligned pointers" {
    var x = MovementState{
        .running = false,
        .crouching = false,
        .jumping = false,
        .in_air = false,
    };

    const running = &x.running;
    running.* = true;

    const crouching = &x.crouching;
    crouching.* = true;

    try expect(@TypeOf(running) == *align(1:0:1) bool);
    try expect(@TypeOf(crouching) == *align(1:1:1) bool);

    try expect(@import("std").meta.eql(x, .{
        .running = true,
        .crouching = true,
        .jumping = false,
        .in_air = false,
    }));
}
```

# Pointeurs C

Jusqu'à présent, nous avons utilisé les types de pointeurs suivants :

- pointeurs à un seul élément - `*T`
- pointeurs à plusieurs éléments - `[*]T`
- tranches - `[]T`

Contrairement aux pointeurs mentionnés ci-dessus, les pointeurs C ne peuvent pas traiter les données spécialement alignées, et peuvent pointer vers l'adresse `0`. Les pointeurs C peuvent être utilisés dans les deux sens entre les nombres entiers, et peuvent également être utilisés pour des pointeurs à un ou plusieurs éléments. Lorsqu'un pointeur C de valeur `0` est converti en un pointeur non optionnel, il s'agit d'un comportement illégal détectable.

En dehors du code C traduit automatiquement, l'utilisation de `[*c]` est presque toujours une mauvaise idée, et ne devrait presque jamais être utilisée.

# Translate-C

Zig fournit la commande `zig translate-c` pour la traduction automatique du code source C.

Créez le fichier `main.c` avec le contenu suivant.
```c
#include <stddef.h>

void int_sort(int* array, size_t count) {
    for (int i = 0; i < count - 1; i++) {
        for (int j = 0; j < count - i - 1; j++) {
            if (array[j] > array[j+1]) {
                int temp = array[j];
                array[j] = array[j+1];
                array[j+1] = temp;
            }
        }
    }
}
```
Lancez la commande `zig translate-c main.c` pour obtenir le code Zig équivalent sur votre console (stdout). Vous pouvez l'insérer dans un fichier avec `zig translate-c main.c > int_sort.zig` (avertissement pour les utilisateurs de windows : l'insertion de piping dans powershell produira un fichier avec un encodage incorrect - utilisez votre éditeur pour corriger cela).

Dans un autre fichier, vous pouvez utiliser `@import("int_sort.zig")` pour utiliser cette fonction.

Actuellement, le code produit peut être inutilement verbeux, bien que translate-c traduise avec succès la plupart des codes C en Zig. Vous pouvez souhaiter utiliser translate-c pour produire du code Zig avant de l'éditer en un code plus idiomatique ; un transfert progressif de C à Zig au sein d'une base de code est un cas d'utilisation supporté.

# cImport

La fonction [`@cImport`](https://ziglang.org/documentation/master/#cImport) de Zig est unique en ce sens qu'elle prend une expression, qui ne peut prendre que [`@cInclude`](https://ziglang.org/documentation/master/#cInclude), [`@cDefine`](https://ziglang.org/documentation/master/#cDefine), et [`@cUndef`](https://ziglang.org/documentation/master/#cUndef). Cela fonctionne de la même manière que translate-c, qui traduit le code C en Zig sous le capot.

[`@cInclude`](https://ziglang.org/documentation/master/#cInclude) prend une chaîne de chemin, et peut ajouter le chemin à la liste des inclusions.

[`@cDefine`](https://ziglang.org/documentation/master/#cDefine) et [`@cUndef`](https://ziglang.org/documentation/master/#cUndef) définissent et annulent des éléments pour l'importation.

Ces trois fonctions fonctionnent exactement comme vous vous attendez à ce qu'elles fonctionnent dans un code C.

Comme [`@import`](https://ziglang.org/documentation/master/#import), elle retourne un type struct avec des déclarations. Il est recommandé de n'utiliser qu'une seule instance de [`@cImport`](https://ziglang.org/documentation/master/#cImport) dans une application pour éviter les collisions de symboles ; les types générés dans un cImport ne seront pas équivalents à ceux générés dans un autre.

cImport n'est disponible que lorsqu'on lie la libc.

# Lier la libc

Lier la libc peut être fait via la ligne de commande via `-lc`, ou via `build.zig` en utilisant `exe.linkLibC();`. La libc utilisée est celle de la cible de la compilation ; Zig fournit des libc pour de nombreuses cibles.

# Zig cc, Zig c++

L'exécutable Zig est livré avec Clang intégré à l'intérieur, ainsi qu'avec les bibliothèques et les en-têtes nécessaires à la compilation croisée pour d'autres systèmes d'exploitation et d'autres architectures.

Cela signifie que non seulement `zig cc` et `zig c++` peuvent compiler du code C et C++ (avec des arguments compatibles avec Clang), mais qu'ils peuvent aussi le faire en respectant le triple argument de cible de Zig ; le seul binaire Zig que vous avez installé a le pouvoir de compiler pour plusieurs cibles différentes sans avoir besoin d'installer plusieurs versions du compilateur ou d'autres addons. L'utilisation de `zig cc` et `zig c++` permet également d'utiliser le système de cache de Zig pour accélérer votre travail.

En utilisant Zig, on peut facilement construire une chaîne d'outils de compilation croisée pour les langages qui utilisent un compilateur C et/ou C++.

Quelques exemples dans la nature :

- [Utilisation de zig cc pour compiler LuaJIT sur aarch64-linux à partir de x86_64-linux](https://andrewkelley.me/post/zig-cc-powerful-drop-in-replacement-gcc-clang.html)

- [Utilisation de zig cc et zig c++ en combinaison avec cgo pour compiler hugo de aarch64-macos à x86_64-linux, avec une liaison statique complète](https://twitter.com/croloris/status/1349861344330330114)

# Fin du chapitre 4

Ce chapitre est incomplet. Dans le futur, il contiendra des choses telles que :
- Appeler du code C depuis Zig et vice versa
- Utiliser `zig build` avec un mélange de code C et Zig

Les commentaires et les PRs sont les bienvenus.
