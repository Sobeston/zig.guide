---
title: "Chapter 5 - Async"
weight: 6
date: 2023-04-28 18:00:00
description: "Chapitre 5 - Apprendre comment fonctionne async en ziglang"
---

Attention : La version actuelle du compilateur ne supporte pas encore async

# Async

Pour bien comprendre async en Zig, il faut se familiariser avec le concept de la pile d'appels. Si vous n'en avez jamais entendu parler, [consultez la page wikipedia](https://en.wikipedia.org/wiki/Call_stack).

<!-- TODO: actually explain the call stack? -->

Un appel de fonction traditionnel comprend trois éléments
1. Initier la fonction appelée avec ses arguments, en poussant le cadre de pile de la fonction.
2. Transférer le contrôle à la fonction
3. À la fin de la fonction, redonner le contrôle à l'appelant, en récupérant la valeur de retour de la fonction et en retirant le cadre de pile de la fonction.

Avec les fonctions asynchrones de Zig, nous pouvons faire plus que cela, le transfert de contrôle étant une conversation bidirectionnelle permanente (c'est-à-dire que nous pouvons donner le contrôle à la fonction et le reprendre plusieurs fois). Pour cette raison, des considérations particulières doivent être prises en compte lors de l'appel d'une fonction dans un contexte asynchrone ; nous ne pouvons plus pousser et sortir le cadre de pile comme d'habitude (car la pile est volatile, et les choses "au-dessus" du cadre de pile actuelle peuvent être écrasées), au lieu de stocker explicitement le cadre de la fonction asynchrone. Bien que la plupart des gens n'utiliseront pas l'ensemble de ses fonctionnalités, ce style d'asynchronisme est utile pour créer des constructions plus puissantes telles que des boucles d'événements.

Le style de l'asynchronisme de Zig peut être décrit comme des coroutines suspendues sans pile. L'asynchronisme de Zig est très différent d'un thread du système d'exploitation qui possède une pile et ne peut être suspendu que par le noyau. De plus, l'async de Zig est là pour vous fournir des structures de flux de contrôle et de génération de code ; l'async n'implique pas le parallélisme ou l'utilisation de threads.

# Suspend / Resume

Dans la section précédente, nous avons parlé de la façon dont les fonctions asynchrones peuvent redonner le contrôle à l'appelant, et de la façon dont la fonction asynchrone peut reprendre le contrôle plus tard. Cette fonctionnalité est fournie par les mots-clés [`suspend`, et `resume`](https://ziglang.org/documentation/master/#Suspend-and-Resume). Lorsqu'une fonction est suspendue, le flux de contrôle revient à l'endroit où il a été repris pour la dernière fois ; lorsqu'une fonction est appelée via une invocation `async`, il s'agit d'une reprise implicite.

Les commentaires dans ces exemples indiquent l'ordre d'exécution. Il y a quelques points à prendre en compte ici :
* Le mot-clé `async` est utilisé pour invoquer des fonctions dans un contexte asynchrone.
* `async func()` renvoie le cadre de la fonction.
* Nous devons stocker ce cadre.
* Le mot-clé `resume` est utilisé sur le cadre, tandis que `suspend` est utilisé à partir de la fonction appelée.

Cet exemple a une suspension, mais pas de reprise correspondante.
```zig
const expect = @import("std").testing.expect;

var foo: i32 = 1;

test "suspend with no resume" {
    var frame = async func(); //1
    _ = frame;
    try expect(foo == 2);     //4
}

fn func() void {
    foo += 1;                 //2
    suspend {}                //3
    foo += 1;                 //never reached!
}
```

Dans un code bien formé, chaque suspension est assortie d'une reprise.

```zig
var bar: i32 = 1;

test "suspend with resume" {
    var frame = async func2();  //1
    resume frame;               //4
    try expect(bar == 3);       //6
}

fn func2() void {
    bar += 1;                   //2
    suspend {}                  //3
    bar += 1;                   //5
}
```

# Async / Await

De la même manière qu'un code bien formé a une suspension pour chaque reprise, chaque invocation de fonction `async` avec une valeur de retour doit être accompagnée d'un `await`. La valeur produite par `await` sur la trame asynchrone correspond au retour de la fonction.

Vous pouvez remarquer que `func3` est une fonction normale (c'est-à-dire qu'elle n'a pas de points de suspension - ce n'est pas une fonction asynchrone). Malgré cela, `func3` peut fonctionner comme une fonction asynchrone lorsqu'elle est appelée depuis une invocation asynchrone ; la convention d'appel de `func3` n'a pas besoin d'être changée en asynchrone - `func3` peut être de n'importe quelle convention d'appel.

```zig
fn func3() u32 {
    return 5;
}

test "async / await" {
    var frame = async func3();
    try expect(await frame == 5);
}
```

L'utilisation de `await` sur une trame asynchrone d'une fonction qui peut être suspendue n'est possible qu'à partir de fonctions asynchrones. En tant que telles, les fonctions qui utilisent `await` sur la trame d'une fonction asynchrone sont également considérées comme des fonctions asynchrones. Si vous pouvez être sûr que la suspension potentielle ne se produira pas, `nosuspend await` l'empêchera de se produire.

# Nosuspend

Lors de l'appel d'une fonction qui est déterminée comme étant asynchrone (c'est à dire qu'elle peut suspendre) sans une invocation `async`, la fonction qui l'a appelée est également traitée comme étant asynchrone. Lorsqu'une fonction d'une convention d'appel concrète (non asynchrone) est déterminée comme ayant des points de suspension, il s'agit d'une erreur de compilation car l'asynchronisme nécessite sa propre convention d'appel. Cela signifie, par exemple, que main ne peut pas être asynchrone.

<!--no_test-->
```zig
pub fn main() !void {
    suspend {}
}
```
(compilé à partir de Windows)
```
C:\zig\lib\zig\std\start.zig:165:1: error: function with calling convention 'Stdcall' cannot be async
fn WinStartup() callconv(.Stdcall) noreturn {
^
C:\zig\lib\zig\std\start.zig:173:65: note: async function call here
    std.os.windows.kernel32.ExitProcess(initEventLoopAndCallMain());
                                                                ^
C:\zig\lib\zig\std\start.zig:276:12: note: async function call here
    return @call(.{ .modifier = .always_inline }, callMain, .{});
           ^
C:\zig\lib\zig\std\start.zig:334:37: note: async function call here
            const result = root.main() catch |err| {
                                    ^
.\main.zig:12:5: note: suspends here
    suspend {}
    ^
```

Si vous voulez appeler une fonction asynchrone sans utiliser une invocation `async`, et sans que l'appelant de la fonction soit également asynchrone, le mot-clé `nosuspend` est utile. Il permet à l'appelant de la fonction asynchrone de ne pas être également asynchrone, en affirmant que les suspensions potentielles ne se produisent pas.

<!--no_test-->
```zig
const std = @import("std");

fn doTicksDuration(ticker: *u32) i64 {
    const start = std.time.milliTimestamp();

    while (ticker.* > 0) {
        suspend {}
        ticker.* -= 1;
    }

    return std.time.milliTimestamp() - start;
}

pub fn main() !void {
    var ticker: u32 = 0;
    const duration = nosuspend doTicksDuration(&ticker);
}
```

Dans le code ci-dessus, si nous changeons la valeur de `ticker` pour qu'elle soit supérieure à 0, il s'agit d'un comportement illégal détectable. Si nous exécutons ce code, nous aurons une erreur de ce type dans les modes de construction sûrs. Comme pour d'autres comportements illégaux dans Zig, le fait que cela se produise dans des modes non sécurisés résultera en un comportement non défini.

```
async function called in nosuspend scope suspended
.\main.zig:16:47: 0x7ff661dd3414 in main (main.obj)
    const duration = nosuspend doTicksDuration(&ticker);
                                              ^
C:\zig\lib\zig\std\start.zig:173:65: 0x7ff661dd18ce in std.start.WinStartup (main.obj)
    std.os.windows.kernel32.ExitProcess(initEventLoopAndCallMain());
                                                                ^
```

# Trames asynchrones, blocs suspendus

`@Frame(function)` renvoie le type de cadre de la fonction. Cela fonctionne pour les fonctions asynchrones et les fonctions sans convention d'appel spécifique.

```zig
fn add(a: i32, b: i32) i64 {
    return a + b;
}

test "@Frame" {
    var frame: @Frame(add) = async add(1, 2);
    try expect(await frame == 3);
}
```

[`@frame()`](https://ziglang.org/documentation/master/#frame) renvoie un pointeur sur le cadre de la fonction courante. Comme pour les points `suspend`, si cet appel est trouvé dans une fonction, on en déduit qu'elle est asynchrone. Tous les pointeurs vers les cadres de fonction coercent vers le type spécial `anyframe`, sur lequel vous pouvez utiliser `resume`.

Cela nous permet, par exemple, d'écrire une fonction qui se reprend elle-même.
```zig
fn double(value: u8) u9 {
    suspend {
        resume @frame();
    }
    return value * 2;
}

test "@frame 1" {
    var f = async double(1);
    try expect(nosuspend await f == 2);
}
```

Ou, plus intéressant encore, nous pouvons l'utiliser pour demander à d'autres fonctions de nous reprendre. Nous introduisons ici les **blocs de suspension**. En entrant dans un bloc de suspension, la fonction asynchrone est déjà considérée comme suspendue (c'est-à-dire qu'elle peut être reprise). Cela signifie que notre fonction peut être reprise par quelque chose d'autre que le dernier resume.

```zig
const std = @import("std");

fn callLater(comptime laterFn: fn () void, ms: u64) void {
    suspend {
        wakeupLater(@frame(), ms);
    }
    laterFn();
}

fn wakeupLater(frame: anyframe, ms: u64) void {
    std.time.sleep(ms * std.time.ns_per_ms);
    resume frame;
}

fn alarm() void {
    std.debug.print("Time's Up!\n", .{});
}

test "@frame 2" {
    nosuspend callLater(alarm, 1000);
}
```

L'utilisation du type de données `anyframe` peut être considérée comme une sorte d'effacement de type, dans la mesure où nous ne sommes plus sûrs du type concret de la fonction ou du cadre de la fonction. C'est utile car cela nous permet toujours de reprendre le cadre - dans beaucoup de code, nous ne nous soucierons pas des détails et nous voudrons juste le reprendre. Cela nous donne un seul type concret que nous pouvons utiliser pour notre logique asynchrone.

L'inconvénient naturel de `anyframe` est que nous avons perdu l'information de type, et nous ne savons plus quel est le type de retour de la fonction. Cela signifie que nous ne pouvons pas attendre une `anyframe`. La solution de Zig est le type `anyframe->T`, où le `T` est le type de retour de la frame.

```zig
fn zero(comptime x: anytype) x {
    return 0;
}

fn awaiter(x: anyframe->f32) f32 {
    return nosuspend await x;
}

test "anyframe->T" {
    var frame = async zero(f32);
    try expect(awaiter(&frame) == 0);
}
```

# Mise en œuvre d'une boucle d'événements de base

Une boucle d'événements est un modèle de conception dans lequel les événements sont distribués et/ou attendus. Cela signifie une sorte de service ou de runtime qui reprend les trames asynchrones suspendues lorsque les conditions sont remplies. C'est le cas d'utilisation le plus puissant et le plus utile de l'asynchronisme de Zig.

Ici, nous allons implémenter une boucle événementielle basique. Celle-ci nous permettra de soumettre des tâches à exécuter dans un temps donné. Nous l'utiliserons pour soumettre des paires de tâches qui afficheront le temps écoulé depuis le début du programme. Voici un exemple de sortie.

```
[task-pair b] it is now 499 ms since start!
[task-pair a] it is now 1000 ms since start!
[task-pair b] it is now 1819 ms since start!
[task-pair a] it is now 2201 ms since start!
```

Voici la mise en œuvre de cette méthode.

<!--no_test-->
```zig
const std = @import("std");

// used to get monotonic time, as opposed to wall-clock time
var timer: ?std.time.Timer = null;
fn nanotime() u64 {
    if (timer == null) {
        timer = std.time.Timer.start() catch unreachable;
    }
    return timer.?.read();
}

// holds the frame, and the nanotime of
// when the frame should be resumed
const Delay = struct {
    frame: anyframe,
    expires: u64,
};

// suspend the caller, to be resumed later by the event loop
fn waitForTime(time_ms: u64) void {
    suspend timer_queue.add(Delay{
        .frame = @frame(),
        .expires = nanotime() + (time_ms * std.time.ns_per_ms),
    }) catch unreachable;
}

fn waitUntilAndPrint(
    time1: u64,
    time2: u64,
    name: []const u8,
) void {
    const start = nanotime();

    // suspend self, to be woken up when time1 has passed
    waitForTime(time1);
    std.debug.print(
        "[{s}] it is now {} ms since start!\n",
        .{ name, (nanotime() - start) / std.time.ns_per_ms },
    );

    // suspend self, to be woken up when time2 has passed
    waitForTime(time2);
    std.debug.print(
        "[{s}] it is now {} ms since start!\n",
        .{ name, (nanotime() - start) / std.time.ns_per_ms },
    );
}

fn asyncMain() void {
    // stores the async frames of our tasks
    var tasks = [_]@Frame(waitUntilAndPrint){
        async waitUntilAndPrint(1000, 1200, "task-pair a"),
        async waitUntilAndPrint(500, 1300, "task-pair b"),
    };
    // |*t| is used, as |t| would be a *const @Frame(...)
    // which cannot be awaited upon
    for (tasks) |*t| await t;
}

// priority queue of tasks
// lower .expires => higher priority => to be executed before
var timer_queue: std.PriorityQueue(Delay, void, cmp) = undefined;
fn cmp(context: void, a: Delay, b: Delay) std.math.Order {
    _ = context;
    return std.math.order(a.expires, b.expires);
}

pub fn main() !void {
    timer_queue = std.PriorityQueue(Delay, void, cmp).init(
        std.heap.page_allocator, undefined
    );
    defer timer_queue.deinit();

    var main_task = async asyncMain();

    // the body of the event loop
    // pops the task which is to be next executed
    while (timer_queue.removeOrNull()) |delay| {
        // wait until it is time to execute next task
        const now = nanotime();
        if (now < delay.expires) {
            std.time.sleep(delay.expires - now);
        }
        // execute next task
        resume delay.frame;
    }

    nosuspend await main_task;
}
```

# Fin du chapitre 5

Ce chapitre est incomplet et devrait à l'avenir contenir l'utilisation de [`std.event.Loop`](https://ziglang.org/documentation/master/std/#std;event.Loop), et des IO événementielles.

Les commentaires et les PRs sont les bienvenus.
