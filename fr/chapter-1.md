---
title : "Chapitre 1 - Les bases"
weight : 2
date: 2023-04-28 18:00:00
description : "Chapitre 1 - Ceci vous permettra de vous familiariser avec la quasi-totalité du langage de programmation Zig. Cette partie du tutoriel devrait pouvoir être parcourue en moins d'une heure."
---

# Affectation

L'affectation de valeur a la syntaxe suivante : `(const|var) identifiant[ : type] = valeur`.

* `const` indique que `identifier` est une **constante** qui stocke une valeur immuable.
* `var` indique que `identifier` est une **variable** qui stocke une valeur mutable.
* `: type` est une annotation de type pour `identifier`, et peut être omis si le type de données de `valeur` peut être déduit.

<!--no_test-->
```zig
const constant: i32 = 5;  // signed 32-bit constant
var variable: u32 = 5000; // unsigned 32-bit variable

// @as performs an explicit type coercion
const inferred_constant = @as(i32, 5);
var inferred_variable = @as(u32, 5000);
```

Les constantes et les variables *doivent* avoir une valeur. Si aucune valeur connue ne peut être donnée, la valeur [`undefined`](https://ziglang.org/documentation/master/#undefined), qui correspond à n'importe quel type, peut être utilisée tant qu'une annotation de type est fournie.

<!--no_test-->
```zig
const a: i32 = undefined;
var b: u32 = undefined;
```

Dans la mesure du possible, les valeurs `const` sont préférées aux valeurs `var`.

# Les tableaux

Les tableaux sont désignés par `[N]T`, où `N` est le nombre d'éléments dans le tableau et `T` est le type de ces éléments (i.e., le type enfant du tableau).

Pour les littéraux de tableau, `N` peut être remplacé par `_` pour déduire la taille du tableau.

<!--no_test-->
```zig
const a = [5]u8{ 'h', 'e', 'l', 'l', 'o' };
const b = [_]u8{ 'w', 'o', 'r', 'l', 'd' };
```

Pour obtenir la taille d'un tableau, il suffit d'accéder à son champ `len`.

<!--no_test-->
```zig
const array = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
const length = array.len; // 5
```

# If

L'instruction if de base de Zig est simple en ce sens qu'elle n'accepte qu'une valeur `bool` (de valeurs `true` ou `false`). Il n'y a pas de concept de valeurs vraies ou fausses.

Ici, nous allons introduire les tests. Sauvegardez le code ci-dessous et compilez-le + exécutez-le avec `zig test nom-de-fichier.zig`. Nous allons utiliser la fonction [`expect`](https://ziglang.org/documentation/master/std/#std;testing.expect) de la bibliothèque standard, qui fera échouer le test s'il reçoit la valeur `false`. Lorsqu'un test échoue, l'erreur et la trace de pile seront affichées.

```zig
const expect = @import("std").testing.expect;

test "if statement" {
    const a = true;
    var x: u16 = 0;
    if (a) {
        x += 1;
    } else {
        x += 2;
    }
    try expect(x == 1);
}
```

Les instructions If fonctionnent également comme des expressions.

```zig
test "if statement expression" {
    const a = true;
    var x: u16 = 0;
    x += if (a) 1 else 2;
    try expect(x == 1);
}
```

# While

La boucle while de Zig comporte trois parties - une condition, un bloc et une expression `continue`.

Sans expression continue.
```zig
test "while" {
    var i: u8 = 2;
    while (i < 100) {
        i *= 2;
    }
    try expect(i == 128);
}
```

Avec une expression `continue`.
```zig
test "while with continue expression" {
    var sum: u8 = 0;
    var i: u8 = 1;
    while (i <= 10) : (i += 1) {
        sum += i;
    }
    try expect(sum == 55);
}
```

Avec un `continue`.

```zig
test "while with continue" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) continue;
        sum += i;
    }
    try expect(sum == 4);
}
```

Avec un ``break``.

```zig
test "while with break" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) break;
        sum += i;
    }
    try expect(sum == 1);
}
```

# For
Les boucles For sont utilisées pour itérer sur des tableaux (et d'autres types, nous y reviendrons plus tard). Les boucles for suivent cette syntaxe. Comme while, les boucles for peuvent utiliser `break` et `continue`. Ici, nous avons dû assigner des valeurs à `_`, car Zig ne nous permet pas d'avoir des valeurs inutilisées.

```zig
test "for" {
    //character literals are equivalent to integer literals
    const string = [_]u8{ 'a', 'b', 'c' };

    for (string, 0..) |character, index| {
        _ = character;
        _ = index;
    }

    for (string) |character| {
        _ = character;
    }

    for (string, 0..) |_, index| {
        _ = index;
    }

    for (string) |_| {}
}
```

# Fonctions

Tous les arguments des fonctions sont immuables - si une copie est souhaitée, l'utilisateur doit explicitement en faire une. Contrairement aux variables qui sont en snake_case, les fonctions sont en camelCase. Voici un exemple de déclaration et d'appel d'une fonction simple.

```zig
fn addFive(x: u32) u32 {
    return x + 5;
}

test "function" {
    const y = addFive(0);
    try expect(@TypeOf(y) == u32);
    try expect(y == 5);
}
```

La récursivité est autorisée :

```zig
fn fibonacci(n: u16) u16 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "function recursion" {
    const x = fibonacci(10);
    try expect(x == 55);
}
```
Lorsque la récursion se produit, le compilateur n'est plus en mesure de déterminer la taille maximale de la pile. Il peut en résulter un comportement dangereux - un débordement de pile. Les détails sur la manière d'obtenir une récursion sûre seront abordés ultérieurement.

Les valeurs peuvent être ignorées en utilisant `_` à la place d'une variable ou d'une déclaration const. Cela ne fonctionne pas à l'échelle globale (c'est-à-dire que cela ne fonctionne qu'à l'intérieur des fonctions et des blocs), et c'est utile pour ignorer les valeurs retournées par les fonctions si vous n'en avez pas besoin.

<!--no_test-->
```zig
_ = 10;
```

# Defer

Defer est utilisé pour exécuter une instruction tout en quittant le bloc courant.

```zig
test "defer" {
    var x: i16 = 5;
    {
        defer x += 2;
        try expect(x == 5);
    }
    try expect(x == 7);
}
```

Lorsqu'il y a plusieurs defers dans un seul bloc, ils sont exécutés dans l'ordre inverse.

```zig
test "multi defer" {
    var x: f32 = 5;
    {
        defer x += 2;
        defer x /= 2;
    }
    try expect(x == 4.5);
}
```

# Erreurs

Un ensemble d'erreurs est comme un enum (nous reviendrons plus tard sur les enums de Zig), où chaque erreur de l'ensemble est une valeur. Il n'y a pas d'exceptions dans Zig ; les erreurs sont des valeurs. Créons un jeu d'erreurs.

```zig
const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};
```
Les ensembles d'erreurs se confondent avec leurs super-ensembles.

```zig
const AllocationError = error{OutOfMemory};

test "coerce error from a subset to a superset" {
    const err: FileOpenError = AllocationError.OutOfMemory;
    try expect(err == FileOpenError.OutOfMemory);
}
```

Un type d'ensemble d'erreurs et un type normal peuvent être combinés avec l'opérateur `!` pour former un type d'union d'erreurs. Les valeurs de ces types peuvent être une valeur d'erreur ou une valeur de type normal.

Créons une valeur d'un type union d'erreur. Ici, [`catch`](https://ziglang.org/documentation/master/#catch) est utilisé, suivi d'une expression qui est évaluée lorsque la valeur qui la précède est une erreur. Le catch est ici utilisé pour fournir une valeur de repli, mais pourrait à la place être un [`noreturn`](https://ziglang.org/documentation/master/#noreturn) - le type de `return`, `while (true)` et d'autres.

```zig
test "error union" {
    const maybe_error: AllocationError!u16 = 10;
    const no_error = maybe_error catch 0;

    try expect(@TypeOf(no_error) == u16);
    try expect(no_error == 10);
}
```

Les fonctions renvoient souvent des unions d'erreurs. En voici une qui utilise un catch, où la syntaxe `|err|` reçoit la valeur de l'erreur. C'est ce qu'on appelle la __capture de charge utile_, et elle est utilisée de la même manière dans de nombreux endroits. Nous en parlerons plus en détail plus loin dans ce chapitre. Remarque : certains langages utilisent une syntaxe similaire pour les lambdas - ce n'est pas le cas de Zig.

```zig
fn failingFunction() error{Oops}!void {
    return error.Oops;
}

test "returning an error" {
    failingFunction() catch |err| {
        try expect(err == error.Oops);
        return;
    };
}
```

`try x` est un raccourci pour `x catch |err| return err`, et est couramment utilisé dans les cas où le traitement d'une erreur n'est pas approprié. Les [``try`](https://ziglang.org/documentation/master/#try) et [``catch`](https://ziglang.org/documentation/master/#catch) de Zig n'ont rien à voir avec les try-catch des autres langages.

```zig
fn failFn() error{Oops}!i32 {
    try failingFunction();
    return 12;
}

test "try" {
    var v = failFn() catch |err| {
        try expect(err == error.Oops);
        return;
    };
    try expect(v == 12); // is never reached
}
```

[`errdefer`](https://ziglang.org/documentation/master/#errdefer) fonctionne comme [`defer`](https://ziglang.org/documentation/master/#defer), mais ne s'exécute que lorsque la fonction est retournée avec une erreur à l'intérieur du bloc [`errdefer`](https://ziglang.org/documentation/master/#errdefer).

```zig
var problems: u32 = 98;

fn failFnCounter() error{Oops}!void {
    errdefer problems += 1;
    try failingFunction();
}

test "errdefer" {
    failFnCounter() catch |err| {
        try expect(err == error.Oops);
        try expect(problems == 99);
        return;
    };
}
```

Les unions d'erreurs renvoyées par une fonction peuvent avoir leurs ensembles d'erreurs déduits en l'absence d'un ensemble d'erreurs explicite. Ce jeu d'erreurs déduit contient toutes les erreurs possibles que la fonction peut renvoyer.

```zig
fn createFile() !void {
    return error.AccessDenied;
}

test "inferred error set" {
    //type coercion successfully takes place
    const x: error{AccessDenied}!void = createFile();

    //Zig does not let us ignore error unions via _ = x;
    //we must unwrap it with "try", "catch", or "if" by any means
    _ = x catch {};
}
```

Les ensembles d'erreurs peuvent être fusionnés.

```zig
const A = error{ NotDir, PathNotFound };
const B = error{ OutOfMemory, PathNotFound };
const C = A || B;
```

`anyerror` est le jeu d'erreurs global qui, du fait qu'il est le sur-ensemble de tous les jeux d'erreurs, peut avoir une erreur de n'importe quel jeu coercitive à une valeur de ce jeu. Son utilisation devrait être généralement évitée.

# Switch

Le `switch` de Zig fonctionne à la fois comme une déclaration et comme une expression. Les types de toutes les branches doivent coercitifs au type qui est commuté. Toutes les valeurs possibles doivent avoir une branche associée - les valeurs ne peuvent pas être laissées de côté. Les cas ne peuvent pas passer par d'autres branches.

Exemple d'instruction d'un `switch`. Le else est nécessaire pour satisfaire l'exhaustivité de ce switch.

```zig
test "switch statement" {
    var x: i8 = 10;
    switch (x) {
        -1...1 => {
            x = -x;
        },
        10, 100 => {
            //special considerations must be made
            //when dividing signed integers
            x = @divExact(x, 10);
        },
        else => {},
    }
    try expect(x == 1);
}
```

Voici la première expression, mais sous la forme d'un `switch`.
```zig
test "switch expression" {
    var x: i8 = 10;
    x = switch (x) {
        -1...1 => -x,
        10, 100 => @divExact(x, 10),
        else => x,
    };
    try expect(x == 1);
}
```

# Sécurité d'exécution

Zig fournit un niveau de sécurité, où les problèmes peuvent être trouvés pendant l'exécution. La sécurité peut être activée ou désactivée. Zig a de nombreux cas de comportement illégal dit __détectable__, ce qui signifie qu'un comportement illégal sera détecté (provoquant une panique) lorsque la sécurité est activée, mais qu'il résultera en un comportement indéfini lorsque la sécurité est désactivée. Il est fortement recommandé aux utilisateurs de développer et de tester leurs logiciels avec la sécurité activée, malgré les inconvénients en termes de vitesse.

Par exemple, la sécurité d'exécution vous protège contre les indices hors limites.

<!--fail_test-->
```zig
test "out of bounds" {
    const a = [3]u8{ 1, 2, 3 };
    var index: u8 = 5;
    const b = a[index];
    _ = b;
}
```
```
test "out of bounds"...index out of bounds
.\tests.zig:43:14: 0x7ff698cc1b82 in test "out of bounds" (test.obj)
    const b = a[index];
             ^
```

L'utilisateur peut choisir de désactiver la sécurité d'exécution pour le bloc courant en utilisant la fonction intégrée [`@setRuntimeSafety`](https://ziglang.org/documentation/master/#setRuntimeSafety).

```zig
test "out of bounds, no safety" {
    @setRuntimeSafety(false);
    const a = [3]u8{ 1, 2, 3 };
    var index: u8 = 5;
    const b = a[index];
    _ = b;
}
```

La sécurité est désactivée pour certains modes de construction (qui seront discutés plus tard).

# Unreachable

[`unreachable`](https://ziglang.org/documentation/master/#unreachable) est une affirmation au compilateur que cette déclaration ne sera pas atteinte. Elle peut être utilisée pour indiquer au compilateur qu'une branche est impossible, ce dont l'optimiseur peut tirer parti. Atteindre un [`unreachable`](https://ziglang.org/documentation/master/#unreachable) est un comportement illégal détectable.

Comme il est du type [`noreturn`](https://ziglang.org/documentation/master/#noreturn), il est compatible avec tous les autres types. Ici, il convertit en u32.
<!--fail_test-->
```zig
test "unreachable" {
    const x: i32 = 1;
    const y: u32 = if (x == 2) 5 else unreachable;
    _ = y;
}
```
```
test "unreachable"...reached unreachable code
.\tests.zig:211:39: 0x7ff7e29b2049 in test "unreachable" (test.obj)
    const y: u32 = if (x == 2) 5 else unreachable;
                                      ^
```

Voici un unreachable utilisé dans un switch.
```zig
fn asciiToUpper(x: u8) u8 {
    return switch (x) {
        'a'...'z' => x + 'A' - 'a',
        'A'...'Z' => x,
        else => unreachable,
    };
}

test "unreachable switch" {
    try expect(asciiToUpper('a') == 'A');
    try expect(asciiToUpper('A') == 'A');
}
```

# Pointeurs

Les pointeurs normaux dans Zig ne sont pas autorisés à avoir 0 ou null comme valeur. Ils suivent la syntaxe `*T`, où `T` est le type enfant.

Le référencement se fait avec `&variable`, et le déréférencement se fait avec `variable.*`.

```zig
fn increment(num: *u8) void {
    num.* += 1;
}

test "pointers" {
    var x: u8 = 1;
    increment(&x);
    try expect(x == 2);
}
```

Essayer de mettre un `*T` à la valeur 0 est un comportement illégal détectable.

<!--fail_test-->
```zig
test "naughty pointer" {
    var x: u16 = 0;
    var y: *u8 = @intToPtr(*u8, x);
    _ = y;
}
```
```
test "naughty pointer"...cast provoque la nullité du pointeur
.\tests.zig:241:18: 0x7ff69ebb22bd in test "naughty pointer" (test.obj)
    var y: *u8 = @intToPtr(*u8, x);
                 ^
```

Zig dispose également de pointeurs constants, qui ne peuvent pas être utilisés pour modifier les données référencées. La référence à une variable constante produira un pointeur constant.

<!--fail_test-->
```zig
test "const pointers" {
    const x: u8 = 1;
    var y = &x;
    y.* += 1;
}
```
```
error: cannot assign to constant
    y.* += 1;
        ^
```

Un `*T` se transforme en un `*const T`.


# Entiers de la taille d'un pointeur

`usize` et `isize` sont des entiers non signés et signés qui ont la même taille que les pointeurs.

```zig
test "usize" {
    try expect(@sizeOf(usize) == @sizeOf(*u8));
    try expect(@sizeOf(isize) == @sizeOf(*u8));
}
```

# Pointeurs à plusieurs éléments

Parfois, vous pouvez avoir un pointeur sur un nombre inconnu d'éléments. `[*]T` est la solution pour cela, qui fonctionne comme `*T` mais supporte aussi la syntaxe d'indexation, l'arithmétique des pointeurs, et le découpage en tranches. Contrairement à `*T`, il ne peut pas pointer vers un type qui n'a pas de taille connue. `*T` est remplacé par `[*]T`.

Ces nombreux pointeurs peuvent pointer sur n'importe quel nombre d'éléments, y compris 0 et 1.

# Les tranches

Les tranches peuvent être considérées comme une paire de `[*]T` (le pointeur vers les données) et un `usize` (le nombre d'éléments). Leur syntaxe est donnée comme `[]T`, avec `T` étant le type enfant. Les tranches sont largement utilisées dans Zig lorsque vous avez besoin d'opérer sur des quantités arbitraires de données. Les tranches ont les mêmes attributs que les pointeurs, ce qui signifie qu'il existe aussi des tranches constantes. Les boucles For opèrent également sur des tranches. Dans Zig, les chaînes littérales sont converties en `[]const u8`.

Ici, la syntaxe `x[n..m]` est utilisée pour créer une tranche à partir d'un tableau. Cela s'appelle __slicing__, et crée une tranche des éléments commençant à `x[n]` et se terminant à `x[m - 1]`. Cet exemple utilise une tranche constante car les valeurs vers lesquelles la tranche pointe n'ont pas besoin d'être modifiées.

```zig
fn total(values: []const u8) usize {
    var sum: usize = 0;
    for (values) |v| sum += v;
    return sum;
}
test "slices" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = array[0..3];
    try expect(total(slice) == 6);
}
```

Lorsque ces valeurs `n` et `m` sont toutes deux connues à la compilation, le découpage en tranches produira en fait un pointeur sur un tableau. Ce n'est pas un problème car un pointeur sur un tableau, c'est-à-dire `*[N]T`, sera converti en `[]T`.

```zig
test "slices 2" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = array[0..3];
    try expect(@TypeOf(slice) == *const [3]u8);
}
```

La syntaxe `x[n..]` peut également être utilisée lorsque vous souhaitez couper jusqu'à la fin.

```zig
test "slices 3" {
    var array = [_]u8{ 1, 2, 3, 4, 5 };
    var slice = array[0..];
    _ = slice;
}
```

Les types qui peuvent être découpés en tranches sont : les tableaux, les pointeurs et les tranches.

# Enums

Les enums de Zig vous permettent de définir des types qui ont un ensemble restreint de valeurs nommées.

Déclarons un enum.
```zig
const Direction = enum { north, south, east, west };
```

Les types enum peuvent avoir des types de balises spécifiés (entiers).
```zig
const Value = enum(u2) { zero, one, two };
```

Les valeurs ordinales d'une énumération commencent à 0. On peut y accéder avec la fonction intégrée [`@enumToInt`](https://ziglang.org/documentation/master/#enumToInt).
```zig
test "enum ordinal value" {
    try expect(@enumToInt(Value.zero) == 0);
    try expect(@enumToInt(Value.one) == 1);
    try expect(@enumToInt(Value.two) == 2);
}
```

Les valeurs peuvent être remplacées par d'autres, les valeurs suivantes continuant à partir de là.
```zig
const Value2 = enum(u32) {
    hundred = 100,
    thousand = 1000,
    million = 1000000,
    next,
};

test "set enum ordinal value" {
    try expect(@enumToInt(Value2.hundred) == 100);
    try expect(@enumToInt(Value2.thousand) == 1000);
    try expect(@enumToInt(Value2.million) == 1000000);
    try expect(@enumToInt(Value2.next) == 1000001);
}
```

Des méthodes peuvent être attribuées aux enums. Elles agissent comme des fonctions à espace de noms qui peuvent être appelées avec la syntaxe point.

```zig
const Suit = enum {
    clubs,
    spades,
    diamonds,
    hearts,
    pub fn isClubs(self: Suit) bool {
        return self == Suit.clubs;
    }
};

test "enum method" {
    try expect(Suit.spades.isClubs() == Suit.isClubs(.spades));
}
```

Les enums peuvent également recevoir des déclarations `var` et `const`. Celles-ci agissent comme des globales à espace de noms, et leurs valeurs ne sont pas liées et ne sont pas attachées aux instances du type enum.

```zig
const Mode = enum {
    var count: u32 = 0;
    on,
    off,
};

test "hmm" {
    Mode.count += 1;
    try expect(Mode.count == 1);
}
```


# Structs

Les structures sont les types de données composites les plus courants de Zig. Elles vous permettent de définir des types qui peuvent stocker un ensemble fixe de champs nommés. Zig ne donne aucune garantie sur l'ordre en mémoire des champs d'une structure, ni sur sa taille. Tout comme les tableaux, les structures sont construites de manière simple avec la syntaxe `T{}`. Voici un exemple de déclaration et de remplissage d'une structure.
```zig
const Vec3 = struct { x: f32, y: f32, z: f32 };

test "struct usage" {
    const my_vector = Vec3{
        .x = 0,
        .y = 100,
        .z = 50,
    };
    _ = my_vector;
}
```

Tous les champs doivent recevoir une valeur.

<!--fail_test-->
```zig
test "missing struct field" {
    const my_vector = Vec3{
        .x = 0,
        .z = 50,
    };
    _ = my_vector;
}
```
```
error: missing field: 'y'
    const my_vector = Vec3{
                        ^
```

Les champs peuvent être définis par défaut :
```zig
const Vec4 = struct { x: f32, y: f32, z: f32 = 0, w: f32 = undefined };

test "struct defaults" {
    const my_vector = Vec4{
        .x = 25,
        .y = -50,
    };
    _ = my_vector;
}
```

Comme les enums, les structures peuvent également contenir des fonctions et des déclarations.

Les structures ont la propriété unique que lorsqu'on leur donne un pointeur, un niveau de déréférencement est effectué automatiquement lors de l'accès aux champs. Remarquez que dans cet exemple, self.x et self.y sont accédés dans la fonction swap sans qu'il soit nécessaire de déréférencer le pointeur self.

```zig
const Stuff = struct {
    x: i32,
    y: i32,
    fn swap(self: *Stuff) void {
        const tmp = self.x;
        self.x = self.y;
        self.y = tmp;
    }
};

test "automatic dereference" {
    var thing = Stuff{ .x = 10, .y = 20 };
    thing.swap();
    try expect(thing.x == 20);
    try expect(thing.y == 10);
}
```

# Unions

Les unions de Zig vous permettent de définir des types qui stockent une valeur parmi de nombreux champs typés possibles ; un seul champ peut être actif à la fois.

Les types union nus n'ont pas de disposition mémoire garantie. Pour cette raison, les unions nues ne peuvent pas être utilisées pour réinterpréter la mémoire. Accéder à un champ dans une union qui n'est pas active est un comportement illégal détectable.

<!--fail_test-->
```zig
const Result = union {
    int: i64,
    float: f64,
    bool: bool,
};

test "simple union" {
    var result = Result{ .int = 1234 };
    result.float = 12.34;
}
```
```
test "simple union"...access of inactive union field
.\tests.zig:342:12: 0x7ff62c89244a in test "simple union" (test.obj)
    result.float = 12.34;
           ^
```

Les unions étiquetées sont des unions qui utilisent un enum pour détecter quel champ est actif. Ici, nous utilisons à nouveau la capture de charge utile pour activer le type de balise d'une union tout en capturant la valeur qu'elle contient. Ici, nous utilisons une *capture de pointeur* ; les valeurs capturées sont immuables, mais avec la syntaxe `|*value|` nous pouvons capturer un pointeur sur les valeurs au lieu des valeurs elles-mêmes. Cela nous permet d'utiliser le déréférencement pour modifier la valeur originale.

```zig
const Tag = enum { a, b, c };

const Tagged = union(Tag) { a: u8, b: f32, c: bool };

test "switch on tagged union" {
    var value = Tagged{ .b = 1.5 };
    switch (value) {
        .a => |*byte| byte.* += 1,
        .b => |*float| float.* *= 2,
        .c => |*b| b.* = !b.*,
    }
    try expect(value.b == 3);
}
```

Le type de balise d'une union étiquetée peut également être déduit. C'est équivalent au type Tagged ci-dessus.

<!--no_test-->
```zig
const Tagged = union(enum) { a: u8, b: f32, c: bool };
```

Les types membres `void` peuvent avoir leur type omis dans la syntaxe. Ici, aucun n'est de type `void`.

```zig
const Tagged2 = union(enum) { a: u8, b: f32, c: bool, none };
```

# Règles relatives aux entiers

Zig supporte les entiers hexagonaux, octaux et binaires.
```zig
const decimal_int: i32 = 98222;
const hex_int: u8 = 0xff;
const another_hex_int: u8 = 0xFF;
const octal_int: u16 = 0o755;
const binary_int: u8 = 0b11110000;
```
Les tirets bas peuvent également être placés entre les chiffres comme séparateur visuel.
```zig
const one_billion: u64 = 1_000_000_000;
const binary_mask: u64 = 0b1_1111_1111;
const permissions: u64 = 0o7_5_5;
const big_address: u64 = 0xFF80_0000_0000_0000;
```

Le "Integer Widening" est autorisé, ce qui signifie que les entiers d'un type peuvent être convertis en un entier d'un autre type, à condition que le nouveau type puisse contenir toutes les valeurs que l'ancien type peut contenir.

```zig
test "integer widening" {
    const a: u8 = 250;
    const b: u16 = a;
    const c: u32 = b;
    try expect(c == a);
}
```

Si vous avez une valeur stockée dans un entier qui ne peut pas être converti dans le type que vous voulez, [`@intCast`](https://ziglang.org/documentation/master/#intCast) peut être utilisé pour convertir explicitement d'un type à l'autre. Si la valeur donnée est en dehors de la plage du type de destination, il s'agit d'un comportement illégal détectable.

```zig
test "@intCast" {
    const x: u64 = 200;
    const y = @intCast(u8, x);
    try expect(@TypeOf(y) == u8);
}
```

Par défaut, les entiers ne sont pas autorisés à déborder. Les débordements sont des comportements illégaux détectables. Parfois, la possibilité de déborder des entiers d'une manière bien définie est un comportement souhaité. Pour ce cas d'utilisation, Zig fournit des opérateurs de débordement.

| Opérateur normal | Opérateur d'enveloppement |
|------------------|---------------------------|
| +                | +%                        |
| -                | -%                        |
| *                | *%                        |
| +=               | +%=                       |
| -=               | -%=                       |
| *=               | *%=                       |

```zig
test "well defined overflow" {
    var a: u8 = 255;
    a +%= 1;
    try expect(a == 0);
}
```

# Les flottants

Les flottants de Zig sont strictement conformes à la norme IEEE à moins que [`@setFloatMode(.Optimized)`](https://ziglang.org/documentation/master/#setFloatMode) ne soit utilisé, ce qui est équivalent à `-ffast-math` de GCC. Les flottants sont convertis en types de flottants plus grands.

```zig
test "float widening" {
    const a: f16 = 0;
    const b: f32 = a;
    const c: f128 = b;
    try expect(c == @as(f128, a));
}
```

Les flottants supportent plusieurs types de littéraux.
```zig
const floating_point: f64 = 123.0E+77;
const another_float: f64 = 123.0;
const yet_another: f64 = 123.0e+77;

const hex_floating_point: f64 = 0x103.70p-5;
const another_hex_float: f64 = 0x103.70;
const yet_another_hex_float: f64 = 0x103.70P-5;
```
Il est également possible de placer des tirets bas entre les chiffres.
```zig
const lightspeed: f64 = 299_792_458.000_000;
const nanosecond: f64 = 0.000_000_001;
const more_hex: f64 = 0x1234_5678.9ABC_CDEFp-10;
```

Les entiers et les flottants peuvent être convertis à l'aide des fonctions intégrées [`@intToFloat`](https://ziglang.org/documentation/master/#intToFloat) et [`@floatToInt`](https://ziglang.org/documentation/master/#floatToInt). [`@intToFloat`](https://ziglang.org/documentation/master/#intToFloat) est toujours sûre, alors que [`@floatToInt`](https://ziglang.org/documentation/master/#floatToInt) est un comportement illégal détectable si la valeur flottante ne peut pas tenir dans le type de destination entier.

```zig
test "int-float conversion" {
    const a: i32 = 0;
    const b = @intToFloat(f32, a);
    const c = @floatToInt(i32, b);
    try expect(c == a);
}
```

# Blocs étiquetés

Les blocs dans Zig sont des expressions et peuvent recevoir des étiquettes, qui sont utilisées pour produire des valeurs. Ici, nous utilisons une étiquette appelée blk. Les blocs produisent des valeurs, ce qui signifie qu'ils peuvent être utilisés à la place d'une valeur. La valeur d'un bloc vide `{}` est une valeur de type `void`.

```zig
test "labelled blocks" {
    const count = blk: {
        var sum: u32 = 0;
        var i: u32 = 0;
        while (i < 10) : (i += 1) sum += i;
        break :blk sum;
    };
    try expect(count == 45);
    try expect(@TypeOf(count) == u32);
}
```

Ceci peut être considéré comme l'équivalent de `i++` en C.
<!--no_test-->
```zig
blk: {
    const tmp = i;
    i += 1;
    break :blk tmp;
}
```

# Boucles étiquetées

Les boucles peuvent être étiquetées, ce qui vous permet de `break` et de `continue` les boucles extérieures.

```zig
test "nested continue" {
    var count: usize = 0;
    outer: for ([_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 }) |_| {
        for ([_]i32{ 1, 2, 3, 4, 5 }) |_| {
            count += 1;
            continue :outer;
        }
    }
    try expect(count == 8);
}
```

# Les boucles en tant qu'expressions

Comme `return`, `break` accepte une valeur. Cela peut être utilisé pour obtenir une valeur à partir d'une boucle. Les boucles dans Zig ont aussi une branche `else` sur les boucles, qui est évaluée quand la boucle n'est pas quittée avec un `break`.

```zig
fn rangeHasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number) {
            break true;
        }
    } else false;
}

test "while loop expression" {
    try expect(rangeHasNumber(0, 10, 3));
}
```

# Les optionnels

Les optionnels utilisent la syntaxe `?T` et sont utilisés pour stocker les données [`null`](https://ziglang.org/documentation/master/#null), ou une valeur de type `T`.

```zig
test "optional" {
    var found_index: ?usize = null;
    const data = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8, 12 };
    for (data, 0..) |v, i| {
        if (v == 10) found_index = i;
    }
    try expect(found_index == null);
}
```

Les optionnels supportent l'expression `orelse`, qui agit lorsque l'optionnel est [`null`](https://ziglang.org/documentation/master/#null). Cela décompose l'optionnel en son type enfant.

```zig
test "orelse" {
    var a: ?f32 = null;
    var b = a orelse 0;
    try expect(b == 0);
    try expect(@TypeOf(b) == f32);
}
```

`.?` est un raccourci pour `orelse unreachable`. On l'utilise quand on sait qu'il est impossible qu'une valeur optionnelle soit nulle, et que l'utiliser pour déballer une valeur [`null`](https://ziglang.org/documentation/master/#null) est un comportement illégal détectable.

```zig
test "orelse unreachable" {
    const a: ?f32 = 5;
    const b = a orelse unreachable;
    const c = a.?;
    try expect(b == c);
    try expect(@TypeOf(c) == f32);
}
```

La capture de charge utile fonctionne dans de nombreux endroits pour les options, ce qui signifie que dans le cas où elle est non nulle, nous pouvons "capturer" sa valeur non nulle.

Ici, nous utilisons une capture de charge utile optionnelle sur le `if` ; a et b sont équivalents ici. `if (b) |valeur|` capture la valeur de `b` (dans le cas où `b` n'est pas nul), et la rend disponible en tant que `valeur`. Comme dans l'exemple de l'union, la valeur capturée est immuable, mais nous pouvons toujours utiliser une capture de pointeur pour modifier la valeur stockée dans `b`.

```zig
test "if optional payload capture" {
    const a: ?i32 = 5;
    if (a != null) {
        const value = a.?;
        _ = value;
    }

    var b: ?i32 = 5;
    if (b) |*value| {
        value.* += 1;
    }
    try expect(b.? == 6);
}
```

Et avec `while` :
```zig
var numbers_left: u32 = 4;
fn eventuallyNullSequence() ?u32 {
    if (numbers_left == 0) return null;
    numbers_left -= 1;
    return numbers_left;
}

test "while null capture" {
    var sum: u32 = 0;
    while (eventuallyNullSequence()) |value| {
        sum += value;
    }
    try expect(sum == 6); // 3 + 2 + 1
}
```

Les pointeurs optionnels et les tranches optionnelles ne prennent pas de mémoire supplémentaire par rapport aux types non optionnels. C'est parce qu'en interne, ils utilisent la valeur 0 du pointeur pour `null`.

C'est ainsi que fonctionnent les pointeurs nuls dans Zig - ils doivent être décompressés en un pointeur non optionnel avant d'être déréférencés, ce qui empêche les déréférences de pointeurs nuls de se produire accidentellement.

# Comptime

Des blocs de code peuvent être exécutés de force au moment de la compilation en utilisant le mot-clé [`comptime`](https://ziglang.org/documentation/master/#comptime). Dans cet exemple, les variables x et y sont équivalentes.

```zig
test "comptime blocks" {
    var x = comptime fibonacci(10);
    _ = x;

    var y = comptime blk: {
        break :blk fibonacci(10);
    };
    _ = y;
}
```

Les littéraux entiers sont du type `comptime_int`. Ils sont spéciaux car ils n'ont pas de taille (ils ne peuvent pas être utilisés à l'exécution !), et ils ont une précision arbitraire. Les valeurs `comptime_int` coercent vers n'importe quel type d'entier qui peut les contenir. Elles peuvent également être converties en nombres flottants. Les caractères littéraux sont de ce type.

```zig
test "comptime_int" {
    const a = 12;
    const b = a + 10;

    const c: u4 = a;
    _ = c;
    const d: f32 = b;
    _ = d;
}
```

`comptime_float` est également disponible, qui est en interne un `f128`. Ils ne peuvent pas être convertis en entiers, même s'ils contiennent une valeur entière.

Les types dans Zig sont des valeurs du type `type`. Ils sont disponibles à la compilation. Nous les avons déjà rencontrés en vérifiant [`@TypeOf`](https://ziglang.org/documentation/master/#TypeOf) et en comparant avec d'autres types, mais nous pouvons faire plus.

```zig
test "branching on types" {
    const a = 5;
    const b: if (a < 10) f32 else i32 = 5;
    _ = b;
}
```

Les paramètres de fonction dans Zig peuvent être étiquetés comme étant [`compomptime`](https://ziglang.org/documentation/master/#comptime). Cela signifie que la valeur passée à ce paramètre de fonction doit être connue au moment de la compilation. Créons une fonction qui renvoie un type. Remarquez que cette fonction est PascalCase, car elle retourne un type.

```zig
fn Matrix(
    comptime T: type,
    comptime width: comptime_int,
    comptime height: comptime_int,
) type {
    return [height][width]T;
}

test "returning a type" {
    try expect(Matrix(f32, 4, 4) == [4][4]f32);
}
```

Nous pouvons réfléchir sur les types en utilisant la fonction intégrée [`@typeInfo`](https://ziglang.org/documentation/master/#typeInfo), qui prend un `type` et renvoie une union étiquetée. Ce type d'union étiquetée peut être trouvé dans [`std.builtin.TypeInfo`](https://ziglang.org/documentation/master/std/#std;builtin.TypeInfo) (des informations sur l'utilisation des imports et de std seront données plus tard).

```zig
fn addSmallInts(comptime T: type, a: T, b: T) T {
    return switch (@typeInfo(T)) {
        .ComptimeInt => a + b,
        .Int => |info| if (info.bits <= 16)
            a + b
        else
            @compileError("ints too large"),
        else => @compileError("only ints accepted"),
    };
}

test "typeinfo switch" {
    const x = addSmallInts(u16, 20, 30);
    try expect(@TypeOf(x) == u16);
    try expect(x == 50);
}
```

Nous pouvons utiliser la fonction [`@Type`](https://ziglang.org/documentation/master/#Type) pour créer un type à partir d'un [`@typeInfo`](https://ziglang.org/documentation/master/#typeInfo). La fonction [`@Type`](https://ziglang.org/documentation/master/#Type) est implémentée pour la plupart des types, mais n'est notamment pas implémentée pour les enums, les unions, les fonctions et les structures.

Ici, la syntaxe des structures anonymes est utilisée avec `.{}`, parce que le `T` dans `T{}` peut être déduit. Les structures anonymes seront abordées en détail plus tard. Dans cet exemple, nous obtiendrons une erreur de compilation si la balise `Int` n'est pas définie.

```zig
fn GetBiggerInt(comptime T: type) type {
    return @Type(.{
        .Int = .{
            .bits = @typeInfo(T).Int.bits + 1,
            .signedness = @typeInfo(T).Int.signedness,
        },
    });
}

test "@Type" {
    try expect(GetBiggerInt(u8) == u9);
    try expect(GetBiggerInt(i31) == i32);
}
```

Renvoyer un type de structure est la façon de créer des structures de données génériques dans Zig. L'utilisation de [`@This`](https://ziglang.org/documentation/master/#This) est nécessaire ici, ce qui permet d'obtenir le type de la structure, de l'union ou de l'enum le plus proche. Ici, [`std.mem.eql`](https://ziglang.org/documentation/master/std/#std;mem.eql) est également utilisé pour comparer deux tranches.

```zig
fn Vec(
    comptime count: comptime_int,
    comptime T: type,
) type {
    return struct {
        data: [count]T,
        const Self = @This();

        fn abs(self: Self) Self {
            var tmp = Self{ .data = undefined };
            for (self.data, 0..) |elem, i| {
                tmp.data[i] = if (elem < 0)
                    -elem
                else
                    elem;
            }
            return tmp;
        }

        fn init(data: [count]T) Self {
            return Self{ .data = data };
        }
    };
}

const eql = @import("std").mem.eql;

test "generic vector" {
    const x = Vec(3, f32).init([_]f32{ 10, -10, 5 });
    const y = x.abs();
    try expect(eql(f32, &y.data, &[_]f32{ 10, 10, 5 }));
}
```

Les types des paramètres des fonctions peuvent également être déduits en utilisant `anytype` à la place d'un type. [`@TypeOf`](https://ziglang.org/documentation/master/#TypeOf) peut alors être utilisé sur le paramètre.

```zig
fn plusOne(x: anytype) @TypeOf(x) {
    return x + 1;
}

test "inferred function parameter" {
    try expect(plusOne(@as(u32, 1)) == 2);
}
```

Comptime introduit également les opérateurs `++` et `**` pour concaténer et répéter les tableaux et les tranches. Ces opérateurs ne fonctionnent pas à l'exécution.

```zig
test "++" {
    const x: [4]u8 = undefined;
    const y = x[0..];

    const a: [6]u8 = undefined;
    const b = a[0..];

    const new = y ++ b;
    try expect(new.len == 10);
}

test "**" {
    const pattern = [_]u8{ 0xCC, 0xAA };
    const memory = pattern ** 3;
    try expect(eql(u8, &memory, &[_]u8{ 0xCC, 0xAA, 0xCC, 0xAA, 0xCC, 0xAA }));
}
```

# Captures de données utiles

Les captures de données utiles utilisent la syntaxe `|valeur|` et apparaissent à de nombreux endroits, dont certains que nous avons déjà vus. Partout où elles apparaissent, elles sont utilisées pour "capturer" la valeur de quelque chose.

Avec les instructions if et les optionnels.
```zig
test "optional-if" {
    var maybe_num: ?usize = 10;
    if (maybe_num) |n| {
        try expect(@TypeOf(n) == usize);
        try expect(n == 10);
    } else {
        unreachable;
    }
}
```

Avec des instructions if et des unions d'erreurs. Le else avec la capture d'erreur est nécessaire ici.
```zig
test "error union if" {
    var ent_num: error{UnknownEntity}!u32 = 5;
    if (ent_num) |entity| {
        try expect(@TypeOf(entity) == u32);
        try expect(entity == 5);
    } else |err| {
        _ = err catch {};
        unreachable;
    }
}
```

Avec des boucles while et des optionnels. Il peut y avoir un bloc else.
```zig
test "while optional" {
    var i: ?u32 = 10;
    while (i) |num| : (i.? -= 1) {
        try expect(@TypeOf(num) == u32);
        if (num == 1) {
            i = null;
            break;
        }
    }
    try expect(i == null);
}
```

Avec des boucles while et des unions d'erreurs. Le else avec la capture d'erreur est nécessaire ici.

```zig
var numbers_left2: u32 = undefined;

fn eventuallyErrorSequence() !u32 {
    return if (numbers_left2 == 0) error.ReachedZero else blk: {
        numbers_left2 -= 1;
        break :blk numbers_left2;
    };
}

test "while error union capture" {
    var sum: u32 = 0;
    numbers_left2 = 3;
    while (eventuallyErrorSequence()) |value| {
        sum += value;
    } else |err| {
        try expect(err == error.ReachedZero);
    }
}
```

Boucles For.
```zig
test "for capture" {
    const x = [_]i8{ 1, 5, 120, -5 };
    for (x) |v| try expect(@TypeOf(v) == i8);
}
```

Switch pour les unions étiquetées.
```zig
const Info = union(enum) {
    a: u32,
    b: []const u8,
    c,
    d: u32,
};

test "switch capture" {
    var b = Info{ .a = 10 };
    const x = switch (b) {
        .b => |str| blk: {
            try expect(@TypeOf(str) == []const u8);
            break :blk 1;
        },
        .c => 2,
        //if these are of the same type, they
        //may be inside the same capture group
        .a, .d => |num| blk: {
            try expect(@TypeOf(num) == u32);
            break :blk num * 2;
        },
    };
    try expect(x == 20);
}
```

Comme nous l'avons vu dans les sections Union et Optional ci-dessus, les valeurs capturées avec la syntaxe `|val|` sont immuables (comme les arguments de fonction), mais nous pouvons utiliser la capture de pointeurs pour modifier les valeurs originales. Ceci capture les valeurs comme des pointeurs qui sont eux-mêmes immuables, mais parce que la valeur est maintenant un pointeur, nous pouvons modifier la valeur originale en la déréférençant :

```zig
test "for with pointer capture" {
    var data = [_]u8{ 1, 2, 3 };
    for (&data) |*byte| byte.* += 1;
    try expect(eql(u8, &data, &[_]u8{ 2, 3, 4 }));
}
```

# Boucles en ligne

Les boucles `inline` sont déroulées, et permettent certaines choses qui ne fonctionnent qu'au moment de la compilation. Ici, nous utilisons une boucle [`for`](https://ziglang.org/documentation/master/#inline-for), mais une boucle [`while`](https://ziglang.org/documentation/master/#inline-while) fonctionne de la même manière.
```zig
test "inline for" {
    const types = [_]type{ i32, f32, u8, bool };
    var sum: usize = 0;
    inline for (types) |T| sum += @sizeOf(T);
    try expect(sum == 10);
}
```

Il est déconseillé d'utiliser ces méthodes pour des raisons de performance, à moins que vous n'ayez testé que le déroulement explicite est plus rapide ; le compilateur a tendance à prendre de meilleures décisions que vous.

# Opaque

Les types [`opaque`](https://ziglang.org/documentation/master/#opaque) dans Zig ont une taille et un alignement inconnus (bien que non nuls). Pour cette raison, ces types de données ne peuvent pas être stockés directement. Ils sont utilisés pour maintenir la sécurité des types avec des pointeurs vers des types sur lesquels nous n'avons pas d'information.

<!--fail_test-->
```zig
const Window = opaque {};
const Button = opaque {};

extern fn show_window(*Window) callconv(.C) void;

test "opaque" {
    var main_window: *Window = undefined;
    show_window(main_window);

    var ok_button: *Button = undefined;
    show_window(ok_button);
}
```
```
./test-c1.zig:653:17: error: expected type '*Window', found '*Button'
    show_window(ok_button);
                ^
./test-c1.zig:653:17: note: pointer type child 'Button' cannot cast into pointer type child 'Window'
    show_window(ok_button);
                ^
```

Les types opaques peuvent avoir des déclarations dans leurs définitions (comme les structs, les enums et les unions).

<!--no_test-->
```zig
const Window = opaque {
    fn show(self: *Window) void {
        show_window(self);
    }
};

extern fn show_window(*Window) callconv(.C) void;

test "opaque with declarations" {
    var main_window: *Window = undefined;
    main_window.show();
}
```

L'utilisation typique d'opaque est de maintenir la sécurité des types lors de l'interopérabilité avec du code C qui n'expose pas d'informations complètes sur les types.

# Structures anonymes

Le type struct peut être omis dans une littérale struct. Ces littéraux peuvent être contraints à d'autres types de structures.

```zig
test "anonymous struct literal" {
    const Point = struct { x: i32, y: i32 };

    var pt: Point = .{
        .x = 13,
        .y = 67,
    };
    try expect(pt.x == 13);
    try expect(pt.y == 67);
}
```

Les structures anonymes peuvent être complètement anonymes, c'est-à-dire sans être contraintes à un autre type de structure.

```zig
test "fully anonymous struct" {
    try dump(.{
        .int = @as(u32, 1234),
        .float = @as(f64, 12.34),
        .b = true,
        .s = "hi",
    });
}

fn dump(args: anytype) !void {
    try expect(args.int == 1234);
    try expect(args.float == 12.34);
    try expect(args.b);
    try expect(args.s[0] == 'h');
    try expect(args.s[1] == 'i');
}
```
<!-- TODO: mention tuple slicing when it's implemented -->

Il est possible de créer des structures anonymes sans nom de champ, appelées __tuples__. Ils ont la plupart des propriétés des tableaux ; les tuples peuvent être itérés, indexés, peuvent être utilisés avec les opérateurs `++` et `**`, et ont un champ len. En interne, ils ont des noms de champs numérotés commençant par `"0"`, auxquels on peut accéder avec la syntaxe spéciale `@"0"` qui agit comme un échappement pour la syntaxe - les choses à l'intérieur de `@""` sont toujours reconnues comme des identificateurs.

Une boucle `inline` doit être utilisée pour itérer sur le tuple, car le type de chaque champ du tuple peut être différent.

```zig
test "tuple" {
    const values = .{
        @as(u32, 1234),
        @as(f64, 12.34),
        true,
        "hi",
    } ++ .{false} ** 2;
    try expect(values[0] == 1234);
    try expect(values[4] == false);
    inline for (values, 0..) |v, i| {
        if (i != 2) continue;
        try expect(v);
    }
    try expect(values.len == 6);
    try expect(values.@"3"[0] == 'h');
}
```

# Terminaison avec sentinelle

Les tableaux, les tranches et de nombreux pointeurs peuvent être terminés par une valeur de leur type enfant. C'est ce qu'on appelle la terminaison avec sentinelle. Ceux-ci suivent la syntaxe `[N:t]T`, `[:t]T`, et `[*:t]T`, où `t` est une valeur du type fils `T`.

Un exemple de tableau à terminaison avec sentinelle. L'élément intégré [`@bitCast`](https://ziglang.org/documentation/master/#bitCast) est utilisé pour effectuer une conversion de type bitwise non sécurisée. Ceci nous montre que le dernier élément du tableau est suivi d'un octet 0.

```zig
test "sentinel termination" {
    const terminated = [3:0]u8{ 3, 2, 1 };
    try expect(terminated.len == 3);
    try expect(@ptrCast(*const [4]u8, &terminated)[3] == 0);
}
```

Le type des chaînes littérales est `*const [N:0]u8`, où N est la longueur de la chaîne. Cela permet aux chaînes littérales d'être converties en tranches terminées par une sentinelle, et en pointeurs multiples terminés par une sentinelle. Note : les chaînes littérales sont encodées en UTF-8.

```zig
test "string literal" {
    try expect(@TypeOf("hello") == *const [5:0]u8);
}
```

`[*:0]u8` et `[*:0]const u8` modélisent parfaitement les chaînes de caractères du langage C.

```zig
test "C string" {
    const c_string: [*:0]const u8 = "hello";
    var array: [5]u8 = undefined;

    var i: usize = 0;
    while (c_string[i] != 0) : (i += 1) {
        array[i] = c_string[i];
    }
}
```

Les types terminés par une sentinelle sont contraints à leurs homologues non terminés par une sentinelle.

```zig
test "coercion" {
    var a: [*:0]u8 = undefined;
    const b: [*]u8 = a;
    _ = b;

    var c: [5:0]u8 = undefined;
    const d: [5]u8 = c;
    _ = d;

    var e: [:10]f32 = undefined;
    const f = e;
    _ = f;
}
```

Le découpage en tranches terminées par une sentinelle est fourni et peut être utilisé pour créer une tranche terminée par une sentinelle avec la syntaxe `x[n..m:t]`, où `t` est la valeur du terminateur. En faisant cela, le programmeur affirme que la mémoire est terminée là où elle devrait l'être - se tromper est un comportement illégal détectable.

```zig
test "sentinel terminated slicing" {
    var x = [_:0]u8{255} ** 3;
    const y = x[0..3 :0];
    _ = y;
}
```

# Vecteurs

Zig fournit des types de vecteurs pour le SIMD. Il ne faut pas les confondre avec les vecteurs au sens mathématique, ou les vecteurs comme std::vector de C++ (pour cela, voir "Arraylist" au chapitre 2). Les vecteurs peuvent être créés en utilisant le [`@Type`](https://ziglang.org/documentation/master/#Type) que nous avons utilisé plus tôt, et [`std.meta.Vector`](https://ziglang.org/documentation/master/std/#std;meta.Vector) fournit un raccourci pour cela.

Les vecteurs ne peuvent avoir comme types enfants que des booléens, des entiers, des flottants et des pointeurs.

Des opérations peuvent être effectuées entre des vecteurs ayant le même type d'enfant et la même longueur. Ces opérations sont effectuées sur chacune des valeurs du vecteur. [`std.meta.eql`](https://ziglang.org/documentation/master/std/#std;meta.eql) est utilisé ici pour vérifier l'égalité entre deux vecteurs (également utile pour d'autres types comme les structs).

```zig
const meta = @import("std").meta;
const Vector = meta.Vector;

test "vector add" {
    const x: Vector(4, f32) = .{ 1, -10, 20, -1 };
    const y: Vector(4, f32) = .{ 2, 10, 0, 1 };
    const z = x + y;
    try expect(meta.eql(z, Vector(4, f32){ 3, 0, 20, 0 }));
}
```

Les vecteurs sont indexables.
```zig
test "vector indexing" {
    const x: Vector(4, u8) = .{ 255, 0, 255, 0 };
    try expect(x[0] == 255);
}
```

La fonction intégrée [`@splat`](https://ziglang.org/documentation/master/#splat) peut être utilisée pour construire un vecteur dont toutes les valeurs sont identiques. Ici, nous l'utilisons pour multiplier un vecteur par un scalaire.

```zig
test "vector * scalar" {
    const x: Vector(3, f32) = .{ 12.5, 37.5, 2.5 };
    const y = x * @splat(3, @as(f32, 2));
    try expect(meta.eql(y, Vector(3, f32){ 25, 75, 5 }));
}
```

Les vecteurs n'ont pas de champ `len` comme les tableaux, mais peuvent quand même être bouclés. Ici, [`std.mem.len`](https://ziglang.org/documentation/master/std/#std;mem.len) est utilisé comme raccourci pour `@typeInfo(@TypeOf(x)).Vector.len`.

```zig
const len = @import("std").mem.len;

test "vector looping" {
    const x = Vector(4, u8){ 255, 0, 255, 0 };
    var sum = blk: {
        var tmp: u10 = 0;
        var i: u8 = 0;
        while (i < 4) : (i += 1) tmp += x[i];
        break :blk tmp;
    };
    try expect(sum == 510);
}
```

Les vecteurs sont contraints à leurs tableaux respectifs.

```zig
const arr: [4]f32 = @Vector(4, f32){ 1, 2, 3, 4 };
```

Il convient de noter que l'utilisation de vecteurs explicites peut entraîner un logiciel plus lent si vous ne prenez pas les bonnes décisions - l'auto-vectorisation du compilateur est assez intelligente en l'état.

# Imports

La fonction intégrée [`@import`](https://ziglang.org/documentation/master/#import) prend un fichier et vous donne un type de structure basé sur ce fichier. Toutes les déclarations étiquetées comme `pub` (pour public) se retrouveront dans ce type de structure, prêtes à l'emploi.

`@import("std")` est un cas spécial dans le compilateur, et vous donne accès à la bibliothèque standard. Les autres [`@import`](https://ziglang.org/documentation/master/#import)s prendront un chemin de fichier, ou un nom de paquet (nous reviendrons sur l'utilisation des paquets dans un chapitre ultérieur).

Nous explorerons plus en détail la bibliothèque standard dans les chapitres suivants.

# Fin du chapitre 1
Dans le prochain chapitre, nous couvrirons les modèles standard, y compris de nombreux domaines utiles de la bibliothèque standard.

Les commentaires et les PRs sont les bienvenus.
