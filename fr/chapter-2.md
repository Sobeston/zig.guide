---
title: "Chapitre 2 - Modèles standard"
weight: 3
date: 2023-04-28 18:00:00
description: "Chapitre 2 - Cette section du tutoriel couvre en détail la bibliothèque standard du langage de programmation Zig."
---

La documentation de la bibliothèque standard générée automatiquement se trouve [ici](https://ziglang.org/documentation/master/std/). L'installation de [ZLS](https://github.com/zigtools/zls/) peut également vous aider à explorer la bibliothèque standard, qui fournit des compléments à ce sujet.

# Allocateurs

La bibliothèque standard Zig fournit un modèle d'allocation de mémoire, qui permet au programmeur de choisir exactement comment les allocations de mémoire sont effectuées dans la bibliothèque standard - aucune allocation ne se fait dans votre dos dans la bibliothèque standard.

L'allocateur le plus basique est [`std.heap.page_allocator`](https://ziglang.org/documentation/master/std/#A;std:heap.page_allocator). Chaque fois que cet allocateur effectue une allocation, il demande à votre système d'exploitation des pages entières de mémoire ; une allocation d'un seul octet réservera probablement plusieurs kibytes. Le fait de demander de la mémoire au système d'exploitation nécessite un appel système, ce qui est extrêmement inefficace en termes de rapidité.

Ici, nous allouons 100 octets sous forme de `[]u8`. Remarquez que defer est utilisé en conjonction avec free - c'est un schéma commun pour la gestion de la mémoire dans Zig.

```zig
const std = @import("std");
const expect = std.testing.expect;

test "allocation" {
    const allocator = std.heap.page_allocator;

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}
```

Le [`std.heap.FixedBufferAllocator`](https://ziglang.org/documentation/master/std/#A;std:heap.FixedBufferAllocator) est un allocateur qui alloue de la mémoire dans un tampon fixe, et ne fait aucune allocation au tas. Ceci est utile lorsque l'utilisation du tas n'est pas souhaitée, par exemple lors de l'écriture d'un noyau. Cela peut également être envisagé pour des raisons de performance. Il vous donnera l'erreur `OutOfMemory` s'il n'a plus d'octets.

```zig
test "fixed buffer allocator" {
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}
```

[`std.heap.ArenaAllocator`](https://ziglang.org/documentation/master/std/#A;std:heap.ArenaAllocator) prend en charge un allocateur enfant, et vous permet d'allouer plusieurs fois et de ne libérer qu'une fois. Ici, `.deinit()` est appelé sur l'arène, ce qui libère toute la mémoire. Utiliser `allocator.free` dans cet exemple serait un no-op (c'est à dire qu'il ne ferait rien).

```zig
test "arena allocator" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    _ = try allocator.alloc(u8, 1);
    _ = try allocator.alloc(u8, 10);
    _ = try allocator.alloc(u8, 100);
}
```

`alloc` et `free` sont utilisés pour les tranches. Pour les éléments uniques, pensez à utiliser `create` et `destroy`.

```zig
test "allocator create/destroy" {
    const byte = try std.heap.page_allocator.create(u8);
    defer std.heap.page_allocator.destroy(byte);
    byte.* = 128;
}
```

La bibliothèque standard Zig dispose également d'un allocateur général : `GeneralPurposeAllocator`. C'est un allocateur sûr qui peut empêcher le double-free, le use-after-free et peut détecter les fuites mémoire. Les contrôles de sécurité et la sécurité des threads peuvent être désactivés via sa structure de configuration (laissée vide ci-dessous). Le GPA de Zig est conçu pour privilégier la sécurité par rapport à la performance, mais il peut tout de même être plusieurs fois plus rapide que le page_allocator.

```zig
test "GPA" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) expect(false) catch @panic("TEST FAIL");
    }

    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);
}
```

Pour des performances élevées (mais très peu de caractéristiques de sécurité !), [`std.heap.c_allocator`](https://ziglang.org/documentation/master/std/#A;std:heap.c_allocator) peut être envisagé. Cela a cependant l'inconvénient de nécessiter de lier Libc, ce qui peut être fait avec `-lc`.

L'exposé de Benjamin Feng [*What's a Memory Allocator Anyway?*](https://www.youtube.com/watch?v=vHWiDx_l4V0) va plus en détail sur ce sujet, et couvre l'implémentation des allocateurs.

# Arraylist

Le [`std.ArrayList`](https://ziglang.org/documentation/master/std/#A;std:ArrayList) est couramment utilisé dans Zig, et sert de tampon dont la taille peut changer. `std.ArrayList(T)` est similaire à `std::vector` en C++ et à `Vec` en Rust. La méthode `deinit()` libère toute la mémoire de l'ArrayList. La mémoire peut être lue et écrite via son champ de tranche - `.items`.

Ici, nous allons introduire l'utilisation de l'allocateur testing. Il s'agit d'un allocateur spécial qui ne fonctionne que dans les tests, et qui peut détecter les fuites de mémoire. Dans votre code, utilisez l'allocateur qui vous convient.

```zig
const eql = std.mem.eql;
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;

test "arraylist" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    try list.append('H');
    try list.append('e');
    try list.append('l');
    try list.append('l');
    try list.append('o');
    try list.appendSlice(" World!");

    try expect(eql(u8, list.items, "Hello World!"));
}
```

# Système de fichiers

Créons et ouvrons un fichier dans notre répertoire de travail actuel, écrivons-y, puis lisons-le. Ici, nous devons utiliser `.seekTo` afin de retourner au début du fichier avant de lire ce que nous avons écrit.

```zig
test "createFile, write, seekTo, read" {
    const file = try std.fs.cwd().createFile(
        "junk_file.txt",
        .{ .read = true },
    );
    defer file.close();

    const bytes_written = try file.writeAll("Hello File!");
    _ = bytes_written;

    var buffer: [100]u8 = undefined;
    try file.seekTo(0);
    const bytes_read = try file.readAll(&buffer);

    try expect(eql(u8, buffer[0..bytes_read], "Hello File!"));
}
```

Les fonctions [`std.fs.openFileAbsolute`](https://ziglang.org/documentation/master/std/#A;std:fs.openFileAbsolute) et les fonctions absolues similaires existent, mais nous ne les testerons pas ici.

Nous pouvons obtenir diverses informations sur les fichiers en utilisant `.stat()` sur eux. `Stat` contient aussi des champs pour .inode et .mode, mais ils ne sont pas testés ici car ils dépendent des types du système d'exploitation actuel.

```zig
test "file stat" {
    const file = try std.fs.cwd().createFile(
        "junk_file2.txt",
        .{ .read = true },
    );
    defer file.close();
    const stat = try file.stat();
    try expect(stat.size == 0);
    try expect(stat.kind == .File);
    try expect(stat.ctime <= std.time.nanoTimestamp());
    try expect(stat.mtime <= std.time.nanoTimestamp());
    try expect(stat.atime <= std.time.nanoTimestamp());
}
```

Nous pouvons créer des répertoires et itérer sur leur contenu. Ici, nous utiliserons un itérateur (discuté plus tard). Ce répertoire (et son contenu) sera supprimé à la fin de ce test.

```zig
test "make dir" {
    try std.fs.cwd().makeDir("test-tmp");
    const iter_dir = try std.fs.cwd().openIterableDir(
        "test-tmp",
        .{},
    );
    defer {
        std.fs.cwd().deleteTree("test-tmp") catch unreachable;
    }

    _ = try iter_dir.dir.createFile("x", .{});
    _ = try iter_dir.dir.createFile("y", .{});
    _ = try iter_dir.dir.createFile("z", .{});

    var file_count: usize = 0;
    var iter = iter_dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .File) file_count += 1;
    }

    try expect(file_count == 3);
}
```

# Readers and Writers

[`std.io.Writer`](https://ziglang.org/documentation/master/std/#A;std:io.Writer) et [`std.io.Reader`](https://ziglang.org/documentation/master/std/#A;std:io.Reader) fournissent des moyens standards d'utiliser les entrées-sorties. `std.ArrayList(u8)` a une méthode `writer` qui nous donne un écrivain. Utilisons-la.

```zig
test "io writer usage" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    const bytes_written = try list.writer().write(
        "Hello World!",
    );
    try expect(bytes_written == 12);
    try expect(eql(u8, list.items, "Hello World!"));
}
```

Ici, nous allons utiliser un lecteur pour copier le contenu du fichier dans un tampon alloué. Le second argument de [`readAllAlloc`](https://ziglang.org/documentation/master/std/#A;std:io.Reader.readAllAlloc) est la taille maximale qu'il peut allouer ; si le fichier est plus grand que cela, il retournera `error.StreamTooLong`.

```zig
test "io reader usage" {
    const message = "Hello File!";

    const file = try std.fs.cwd().createFile(
        "junk_file2.txt",
        .{ .read = true },
    );
    defer file.close();

    try file.writeAll(message);
    try file.seekTo(0);

    const contents = try file.reader().readAllAlloc(
        test_allocator,
        message.len,
    );
    defer test_allocator.free(contents);

    try expect(eql(u8, contents, message));
}
```

Un cas d'utilisation courant des lecteurs est de lire jusqu'à la ligne suivante (par exemple pour la saisie de l'utilisateur). Ici, nous allons le faire avec le fichier [`std.io.getStdIn()`](https://ziglang.org/documentation/master/std/#A;std:io.getStdIn).

```zig
fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    var line = (try reader.readUntilDelimiterOrEof(
        buffer,
        '\n',
    )) orelse return null;
    // trim annoying windows-only carriage return character
    if (@import("builtin").os.tag == .windows) {
        return std.mem.trimRight(u8, line, "\r");
    } else {
        return line;
    }
}

test "read until next line" {
    const stdout = std.io.getStdOut();
    const stdin = std.io.getStdIn();

    try stdout.writeAll(
        \\ Enter your name:
    );

    var buffer: [100]u8 = undefined;
    const input = (try nextLine(stdin.reader(), &buffer)).?;
    try stdout.writer().print(
        "Your name is: \"{s}\"\n",
        .{input},
    );
}
```

Un type [`std.io.Writer`](https://ziglang.org/documentation/master/std/#A;std:io.Writer) est constitué d'un type de contexte, d'un jeu d'erreurs et d'une fonction d'écriture. La fonction d'écriture doit prendre en compte le type de contexte et une tranche d'octets. La fonction d'écriture doit également renvoyer une union d'erreurs du jeu d'erreurs du type Writer et le nombre d'octets écrits. Créons un type qui implémente un écrivain.

```zig
// Don't create a type like this! Use an
// arraylist with a fixed buffer allocator
const MyByteList = struct {
    data: [100]u8 = undefined,
    items: []u8 = &[_]u8{},

    const Writer = std.io.Writer(
        *MyByteList,
        error{EndOfBuffer},
        appendWrite,
    );

    fn appendWrite(
        self: *MyByteList,
        data: []const u8,
    ) error{EndOfBuffer}!usize {
        if (self.items.len + data.len > self.data.len) {
            return error.EndOfBuffer;
        }
        std.mem.copy(
            u8,
            self.data[self.items.len..],
            data,
        );
        self.items = self.data[0 .. self.items.len + data.len];
        return data.len;
    }

    fn writer(self: *MyByteList) Writer {
        return .{ .context = self };
    }
};

test "custom writer" {
    var bytes = MyByteList{};
    _ = try bytes.writer().write("Hello");
    _ = try bytes.writer().write(" Writer!");
    try expect(eql(u8, bytes.items, "Hello Writer!"));
}
```

# Formatage

[`std.fmt`](https://ziglang.org/documentation/master/std/#A;std:fmt) fournit des moyens de formater des données vers et depuis des chaînes de caractères.

Un exemple basique de création d'une chaîne formatée. La chaîne de formatage doit être connue à la compilation. Le `d` indique ici que nous voulons un nombre décimal.

```zig
test "fmt" {
    const string = try std.fmt.allocPrint(
        test_allocator,
        "{d} + {d} = {d}",
        .{ 9, 10, 19 },
    );
    defer test_allocator.free(string);

    try expect(eql(u8, string, "9 + 10 = 19"));
}
```

Les écrivains ont une méthode `print` qui fonctionne de la même manière.

```zig
test "print" {
    var list = std.ArrayList(u8).init(test_allocator);
    defer list.deinit();
    try list.writer().print(
        "{} + {} = {}",
        .{ 9, 10, 19 },
    );
    try expect(eql(u8, list.items, "9 + 10 = 19"));
}
```

Prenez un moment pour apprécier le fait que vous savez maintenant de fond en comble comment fonctionne l'impression de hello world. [`std.debug.print`](https://ziglang.org/documentation/master/std/#A;std:debug.print) fonctionne de la même manière, sauf qu'elle écrit sur stderr et qu'elle est protégée par un mutex.

```zig
test "hello world" {
    const out_file = std.io.getStdOut();
    try out_file.writer().print(
        "Hello, {s}!\n",
        .{"World"},
    );
}
```

Jusqu'à présent, nous avons utilisé le spécificateur de format `{s}` pour imprimer des chaînes de caractères. Ici, nous allons utiliser `{any}`, qui nous donne le formatage par défaut.

```zig
test "array printing" {
    const string = try std.fmt.allocPrint(
        test_allocator,
        "{any} + {any} = {any}",
        .{
            @as([]const u8, &[_]u8{ 1, 4 }),
            @as([]const u8, &[_]u8{ 2, 5 }),
            @as([]const u8, &[_]u8{ 3, 9 }),
        },
    );
    defer test_allocator.free(string);

    try expect(eql(
        u8,
        string,
        "{ 1, 4 } + { 2, 5 } = { 3, 9 }",
    ));
}
```

Créons un type avec un formatage personnalisé en lui donnant une fonction `format`. Cette fonction doit être marquée comme `pub` pour que std.fmt puisse y accéder (nous reviendrons sur les paquets plus tard). Vous pouvez remarquer l'utilisation de `{s}` au lieu de `{}` - c'est le spécificateur de format pour les chaînes de caractères (nous reviendrons sur les spécificateurs de format plus tard). Il est utilisé ici car `{}` utilise par défaut l'impression des tableaux plutôt que celle des chaînes de caractères.

```zig
const Person = struct {
    name: []const u8,
    birth_year: i32,
    death_year: ?i32,
    pub fn format(
        self: Person,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("{s} ({}-", .{
            self.name, self.birth_year,
        });

        if (self.death_year) |year| {
            try writer.print("{}", .{year});
        }

        try writer.writeAll(")");
    }
};

test "custom fmt" {
    const john = Person{
        .name = "John Carmack",
        .birth_year = 1970,
        .death_year = null,
    };

    const john_string = try std.fmt.allocPrint(
        test_allocator,
        "{s}",
        .{john},
    );
    defer test_allocator.free(john_string);

    try expect(eql(
        u8,
        john_string,
        "John Carmack (1970-)",
    ));

    const claude = Person{
        .name = "Claude Shannon",
        .birth_year = 1916,
        .death_year = 2001,
    };

    const claude_string = try std.fmt.allocPrint(
        test_allocator,
        "{s}",
        .{claude},
    );
    defer test_allocator.free(claude_string);

    try expect(eql(
        u8,
        claude_string,
        "Claude Shannon (1916-2001)",
    ));
}
```

# JSON

Analysons une chaîne json en un type struct, en utilisant l'analyseur de flux.

```zig
const Place = struct { lat: f32, long: f32 };

test "json parse" {
    var stream = std.json.TokenStream.init(
        \\{ "lat": 40.684540, "long": -74.401422 }
    );
    const x = try std.json.parse(Place, &stream, .{});

    try expect(x.lat == 40.684540);
    try expect(x.long == -74.401422);
}
```

Et en utilisant stringify pour transformer des données arbitraires en une chaîne.

```zig
test "json stringify" {
    const x = Place{
        .lat = 51.997664,
        .long = -0.740687,
    };

    var buf: [100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    var string = std.ArrayList(u8).init(fba.allocator());
    try std.json.stringify(x, .{}, string.writer());

    try expect(eql(u8, string.items,
        \\{"lat":5.19976654e+01,"long":-7.40687012e-01}
    ));
}
```

L'analyseur json nécessite un allocateur pour les types string, array et map de javascript. Cette mémoire peut être libérée en utilisant [`std.json.parseFree`](https://ziglang.org/documentation/master/std/#A;std:json.parseFree).

```zig
test "json parse with strings" {
    var stream = std.json.TokenStream.init(
        \\{ "name": "Joe", "age": 25 }
    );

    const User = struct { name: []u8, age: u16 };

    const x = try std.json.parse(
        User,
        &stream,
        .{ .allocator = test_allocator },
    );

    defer std.json.parseFree(
        User,
        x,
        .{ .allocator = test_allocator },
    );

    try expect(eql(u8, x.name, "Joe"));
    try expect(x.age == 25);
}
```

# Nombres aléatoires

Ici, nous créons un nouveau prng en utilisant une graine aléatoire de 64 bits. a, b, c, et d reçoivent des valeurs aléatoires via ce prng. Les expressions donnant les valeurs de c et d sont équivalentes. Le `Prng par défaut` est `Xoroshiro128` ; il y a d'autres prngs disponibles dans std.rand.

```zig
test "random numbers" {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    const a = rand.float(f32);
    const b = rand.boolean();
    const c = rand.int(u8);
    const d = rand.intRangeAtMost(u8, 0, 255);

    //suppress unused constant compile error
    _ = .{ a, b, c, d };
}
```

Un random cryptographiquement sécurisé est également disponible.

```zig
test "crypto random numbers" {
    const rand = std.crypto.random;

    const a = rand.float(f32);
    const b = rand.boolean();
    const c = rand.int(u8);
    const d = rand.intRangeAtMost(u8, 0, 255);

    //suppress unused constant compile error
    _ = .{ a, b, c, d };
}
```

# Crypto

[`std.crypto`](https://ziglang.org/documentation/master/std/#A;std:crypto) inclut de nombreux utilitaires cryptographiques, y compris :
- AES (Aes128, Aes256)
- Échange de clés Diffie-Hellman (x25519)
- Arithmétique des courbes elliptiques (curve25519, edwards25519, ristretto255)
- Hachage crypto-sécurisé (blake2, Blake3, Gimli, Md5, sha1, sha2, sha3)
- Fonctions MAC (Ghash, Poly1305)
- Chiffres de flux (ChaCha20IETF, ChaCha20With64BitNonce, XChaCha20IETF, Salsa20, XSalsa20)

Cette liste n'est pas exhaustive. Pour des informations plus approfondies, essayez [A tour of std.crypto in Zig 0.7.0 - Frank Denis](https://www.youtube.com/watch?v=9t6Y7KoCvyk).

# Threads

Alors que Zig fournit des moyens plus avancés d'écrire du code concurrent et parallèle, [`std.Thread`](https://ziglang.org/documentation/master/std/#A;std:Thread) est disponible pour utiliser les threads du système d'exploitation. Utilisons un thread du système d'exploitation.

```zig
fn ticker(step: u8) void {
    while (true) {
        std.time.sleep(1 * std.time.ns_per_s);
        tick += @as(isize, step);
    }
}

var tick: isize = 0;

test "threading" {
    var thread = try std.Thread.spawn(.{}, ticker, .{@as(u8, 1)});
    _ = thread;
    try expect(tick == 0);
    std.time.sleep(3 * std.time.ns_per_s / 2);
    try expect(tick == 1);
}
```

Les threads, cependant, ne sont pas particulièrement utiles sans stratégies pour la sécurité des threads.

# Les tables de hachage

La bibliothèque standard fournit [`std.AutoHashMap`](https://ziglang.org/documentation/master/std/#A;std:AutoHashMap), qui vous permet de créer facilement un type de table de hachage à partir d'un type de clé et d'un type de valeur. Ceux-ci doivent être initiés avec un allocateur.

Plaçons quelques valeurs dans une table de hachage.

```zig
test "hashing" {
    const Point = struct { x: i32, y: i32 };

    var map = std.AutoHashMap(u32, Point).init(
        test_allocator,
    );
    defer map.deinit();

    try map.put(1525, .{ .x = 1, .y = -4 });
    try map.put(1550, .{ .x = 2, .y = -3 });
    try map.put(1575, .{ .x = 3, .y = -2 });
    try map.put(1600, .{ .x = 4, .y = -1 });

    try expect(map.count() == 4);

    var sum = Point{ .x = 0, .y = 0 };
    var iterator = map.iterator();

    while (iterator.next()) |entry| {
        sum.x += entry.value_ptr.x;
        sum.y += entry.value_ptr.y;
    }

    try expect(sum.x == 10);
    try expect(sum.y == -10);
}
```

`.fetchPut` place une valeur dans la table de hachage, retournant une valeur s'il y a déjà eu une valeur pour cette clé.

```zig
test "fetchPut" {
    var map = std.AutoHashMap(u8, f32).init(
        test_allocator,
    );
    defer map.deinit();

    try map.put(255, 10);
    const old = try map.fetchPut(255, 100);

    try expect(old.?.value == 10);
    try expect(map.get(255).? == 100);
}
```

[`std.StringHashMap`](https://ziglang.org/documentation/master/std/#A;std:StringHashMap) est également fourni lorsque vous avez besoin de chaînes de caractères comme clés.

```zig
test "string hashmap" {
    var map = std.StringHashMap(enum { cool, uncool }).init(
        test_allocator,
    );
    defer map.deinit();

    try map.put("loris", .uncool);
    try map.put("me", .cool);

    try expect(map.get("me").? == .cool);
    try expect(map.get("loris").? == .uncool);
}
```

[`std.StringHashMap`](https://ziglang.org/documentation/master/std/#A;std:StringHashMap) et [`std.AutoHashMap`](https://ziglang.org/documentation/master/std/#A;std:AutoHashMap) sont juste des wrappers pour [`std.HashMap`](https://ziglang.org/documentation/master/std/#A;std:HashMap). Si ces deux méthodes ne répondent pas à vos besoins, l'utilisation directe de [`std.HashMap`](https://ziglang.org/documentation/master/std/#A;std:HashMap) vous donne beaucoup plus de contrôle.

Si vous voulez que vos éléments soient soutenus par un tableau, essayez [`std.ArrayHashMap`](https://ziglang.org/documentation/master/std/#A;std:ArrayHashMap) et son wrapper [`std.AutoArrayHashMap`](https://ziglang.org/documentation/master/std/#A;std:AutoArrayHashMap).

# Piles

[`std.ArrayList`](https://ziglang.org/documentation/master/std/#A;std:ArrayList) fournit les méthodes nécessaires pour l'utiliser comme une pile. Voici un exemple de création d'une liste de parenthèses appariées.

```zig
test "stack" {
    const string = "(()())";
    var stack = std.ArrayList(usize).init(
        test_allocator,
    );
    defer stack.deinit();

    const Pair = struct { open: usize, close: usize };
    var pairs = std.ArrayList(Pair).init(
        test_allocator,
    );
    defer pairs.deinit();

    for (string, 0..) |char, i| {
        if (char == '(') try stack.append(i);
        if (char == ')')
            try pairs.append(.{
                .open = stack.pop(),
                .close = i,
            });
    }

    for (pairs.items, 0..) |pair, i| {
        try expect(std.meta.eql(pair, switch (i) {
            0 => Pair{ .open = 1, .close = 2 },
            1 => Pair{ .open = 3, .close = 4 },
            2 => Pair{ .open = 0, .close = 5 },
            else => unreachable,
        }));
    }
}
```

# Tri

La bibliothèque standard fournit des utilitaires pour trier les tranches sur place. Son utilisation de base est la suivante.

```zig
test "sorting" {
    var data = [_]u8{ 10, 240, 0, 0, 10, 5 };
    std.sort.sort(u8, &data, {}, comptime std.sort.asc(u8));
    try expect(eql(u8, &data, &[_]u8{ 0, 0, 5, 10, 10, 240 }));
    std.sort.sort(u8, &data, {}, comptime std.sort.desc(u8));
    try expect(eql(u8, &data, &[_]u8{ 240, 10, 10, 5, 0, 0 }));
}
```

[`std.sort.asc`](https://ziglang.org/documentation/master/std/#A;std:sort.asc) et [`.desc`](https://ziglang.org/documentation/master/std/#A;std:sort.desc) créent une fonction de comparaison pour le type donné au moment du calcul ; si des types non numériques doivent être triés, l'utilisateur doit fournir sa propre fonction de comparaison.

[`std.sort.sort`](https://ziglang.org/documentation/master/std/#A;std:sort.sort) a une valeur de O(n) dans le meilleur des cas, et une valeur moyenne et la pire des cas de O(n*log(n)).

# Itérateurs

Il est courant d'avoir un type de structure avec une fonction `next` avec une option dans son type de retour, de sorte que la fonction puisse retourner un null pour indiquer que l'itération est terminée.

[`std.mem.SplitIterator`](https://ziglang.org/documentation/master/std/#A;std:mem.SplitIterator) (et le subtilement différent [`std.mem.TokenIterator`](https://ziglang.org/documentation/master/std/#A;std:mem.TokenIterator)) est un exemple de ce modèle.
```zig
test "split iterator" {
    const text = "robust, optimal, reusable, maintainable, ";
    var iter = std.mem.split(u8, text, ", ");
    try expect(eql(u8, iter.next().?, "robust"));
    try expect(eql(u8, iter.next().?, "optimal"));
    try expect(eql(u8, iter.next().?, "reusable"));
    try expect(eql(u8, iter.next().?, "maintainable"));
    try expect(eql(u8, iter.next().?, ""));
    try expect(iter.next() == null);
}
```

Certains itérateurs ont un type de retour `!?T`, par opposition à ?T. `!?T` exige que nous décompressions l'union d'erreur avant l'optionnel, ce qui signifie que le travail effectué pour arriver à l'itération suivante peut être une erreur. Voici un exemple de ce que l'on peut faire avec une boucle. [`cwd`](https://ziglang.org/documentation/master/std/#std;fs.cwd) doit être ouvert avec des permissions d'itération pour que l'itérateur de répertoire fonctionne.

```zig
test "iterator looping" {
    var iter = (try std.fs.cwd().openIterableDir(
        ".",
        .{},
    )).iterate();

    var file_count: usize = 0;
    while (try iter.next()) |entry| {
        if (entry.kind == .File) file_count += 1;
    }

    try expect(file_count > 0);
}
```

Ici, nous allons implémenter un itérateur personnalisé. Celui-ci va itérer sur une tranche de chaînes, en obtenant les chaînes qui contiennent une chaîne donnée.

```zig
const ContainsIterator = struct {
    strings: []const []const u8,
    needle: []const u8,
    index: usize = 0,
    fn next(self: *ContainsIterator) ?[]const u8 {
        const index = self.index;
        for (self.strings[index..]) |string| {
            self.index += 1;
            if (std.mem.indexOf(u8, string, self.needle)) |_| {
                return string;
            }
        }
        return null;
    }
};

test "custom iterator" {
    var iter = ContainsIterator{
        .strings = &[_][]const u8{ "one", "two", "three" },
        .needle = "e",
    };

    try expect(eql(u8, iter.next().?, "one"));
    try expect(eql(u8, iter.next().?, "three"));
    try expect(iter.next() == null);
}
```

# Spécification de formatage
[`std.fmt`](https://ziglang.org/documentation/master/std/#std;fmt) fournit des options pour formater différents types de données.

`std.fmt.fmtSliceHexLower` et `std.fmt.fmtSliceHexUpper` fournissent le formatage hexadécimal pour les chaînes de caractères ainsi que `{x}` et `{X}` pour les ints.
```zig
const bufPrint = std.fmt.bufPrint;

test "hex" {
    var b: [8]u8 = undefined;

    _ = try bufPrint(&b, "{X}", .{4294967294});
    try expect(eql(u8, &b, "FFFFFFFE"));

    _ = try bufPrint(&b, "{x}", .{4294967294});
    try expect(eql(u8, &b, "fffffffe"));

    _ = try bufPrint(&b, "{}", .{std.fmt.fmtSliceHexLower("Zig!")});
    try expect(eql(u8, &b, "5a696721"));
}
```

`{d}` effectue le formatage décimal pour les types numériques.

```zig
test "decimal float" {
    var b: [4]u8 = undefined;
    try expect(eql(
        u8,
        try bufPrint(&b, "{d}", .{16.5}),
        "16.5",
    ));
}
```

`{c}` transforme un octet en caractère ascii.```zig
```zig
test "ascii fmt" {
    var b: [1]u8 = undefined;
    _ = try bufPrint(&b, "{c}", .{66});
    try expect(eql(u8, &b, "B"));
}
```

`std.fmt.fmtIntSizeDec` and `std.fmt.fmtIntSizeBin` output memory sizes in metric (1000) and power-of-two (1024) based notation.

```zig
test "B Bi" {
    var b: [32]u8 = undefined;

    try expect(eql(u8, try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeDec(1)}), "1B"));
    try expect(eql(u8, try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeBin(1)}), "1B"));

    try expect(eql(u8, try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeDec(1024)}), "1.024kB"));
    try expect(eql(u8, try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeBin(1024)}), "1KiB"));

    try expect(eql(
        u8,
        try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeDec(1024 * 1024 * 1024)}),
        "1.073741824GB",
    ));
    try expect(eql(
        u8,
        try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeBin(1024 * 1024 * 1024)}),
        "1GiB",
    ));
}
```

`{b}` et `{o}` affichent les entiers au format binaire et octal.

```zig
test "binary, octal fmt" {
    var b: [8]u8 = undefined;

    try expect(eql(
        u8,
        try bufPrint(&b, "{b}", .{254}),
        "11111110",
    ));

    try expect(eql(
        u8,
        try bufPrint(&b, "{o}", .{254}),
        "376",
    ));
}
```

`{*}` effectue un formatage de pointeur, en imprimant l'adresse plutôt que la valeur.
```zig
test "pointer fmt" {
    var b: [16]u8 = undefined;
    try expect(eql(
        u8,
        try bufPrint(&b, "{*}", .{@intToPtr(*u8, 0xDEADBEEF)}),
        "u8@deadbeef",
    ));
}
```

`{e}` affiche les flottants en notation scientifique.
```zig
test "scientific" {
    var b: [16]u8 = undefined;

    try expect(eql(
        u8,
        try bufPrint(&b, "{e}", .{3.14159}),
        "3.14159e+00",
    ));
}
```

`{s}` produit des chaînes de caractères.
```zig
test "string fmt" {
    var b: [6]u8 = undefined;
    const hello: [*:0]const u8 = "hello!";

    try expect(eql(
        u8,
        try bufPrint(&b, "{s}", .{hello}),
        "hello!",
    ));
}
```

Cette liste n'est pas exhaustive.

# Formatage avancé

Jusqu'à présent, nous n'avons couvert que les spécificateurs de formatage. Les chaînes de formatage suivent en fait ce format, où entre chaque paire de crochets se trouve un paramètre que vous devez remplacer par quelque chose.

`{[position][spécificateur] :[remplissage][alignement][largeur].[précision]}`

| Nom         | Signification
|-------------|----------------------------------------------------------------------------------------------------------------|
| Position    | L'index de l'argument qui doit être inséré.                                                                    |
| Specifier   | Une option de formatage dépendante du type                                                                     |
| Remplissage | Un seul caractère utilisé pour le remplissage                                                                  |
| Alignement  | Un des trois caractères '<', '^' ou '>' ; ceux-ci correspondent à l'alignement à gauche, au milieu et à droite |
| Largeur     | Largeur totale du champ (caractères)                                                                           |
| Précision   | Nombre de décimales d'un nombre formaté.                                                                       |


Utilisation de la position.
```zig
test "position" {
    var b: [3]u8 = undefined;
    try expect(eql(
        u8,
        try bufPrint(&b, "{0s}{0s}{1s}", .{ "a", "b" }),
        "aab",
    ));
}
```

Remplissage, alignement et largeur utilisés.
```zig
test "fill, alignment, width" {
    var b: [6]u8 = undefined;

    try expect(eql(
        u8,
        try bufPrint(&b, "{s: <5}", .{"hi!"}),
        "hi!  ",
    ));

    try expect(eql(
        u8,
        try bufPrint(&b, "{s:_^6}", .{"hi!"}),
        "_hi!__",
    ));

    try expect(eql(
        u8,
        try bufPrint(&b, "{s:!>4}", .{"hi!"}),
        "!hi!",
    ));
}
```

Utilisation d'un spécificateur avec précision.
```zig
test "precision" {
    var b: [4]u8 = undefined;
    try expect(eql(
        u8,
        try bufPrint(&b, "{d:.2}", .{3.14159}),
        "3.14",
    ));
}
```

# Fin du chapitre 2

Ce chapitre est incomplet. Il contiendra à l'avenir des éléments tels que :

- Mathématiques de précision arbitraire
- Listes chaînées
- Les files d'attente
- Mutex
- Atomique
- Recherche
- Journalisation

Les commentaires et les PRs sont les bienvenus.
