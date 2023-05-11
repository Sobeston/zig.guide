---
title : "Chapitre 0 - Mise en route"
weight : 1
date: 2023-04-28 18:00:00
description : "Ziglearn - Un guide / tutoriel pour le langage de programmation Zig. Installez et démarrez avec ziglang ici."
---

# Bienvenue

[Zig](https://ziglang.org) est un langage de programmation généraliste et une chaîne d'outils pour maintenir des logiciels __robustes__, __optimaux__, et __réutilisables__.

Attention : la dernière version majeure est la 0.10.1 - Zig est encore pré-1.0 ; l'utilisation en production n'est toujours pas recommandée et vous pouvez rencontrer des bugs de compilateur.

Pour suivre ce guide, nous supposons que vous avez :
   * Une expérience préalable de la programmation
   * Une certaine compréhension des concepts de programmation de bas niveau

La connaissance d'un langage comme C, C++, Rust, Go, Pascal ou similaire sera utile pour suivre ce guide. Vous devez disposer d'un éditeur, d'un terminal et d'une connexion internet. Ce guide n'est pas officiel et n'est pas affilié à la Zig Software Foundation, et il est conçu pour être lu dans l'ordre depuis le début.

# Installation

**Ce guide suppose que vous utilisez un master build** de Zig plutôt que la dernière version majeure, ce qui signifie que vous téléchargez un binaire depuis le site ou que vous compilez à partir des sources ; **la version de Zig dans votre gestionnaire de paquets est probablement obsolète**. Ce guide ne prend pas en charge Zig 0.10.1.

1.  Téléchargez et extrayez un binaire maître préconstruit de Zig à partir de :
```
https://ziglang.org/download/
```

2. Ajoutez Zig à votre chemin d'accès
   - linux, macos, bsd

      Ajoutez l'emplacement de votre binaire Zig à votre variable d'environnement `PATH`. Pour une installation, ajoutez `export PATH=$PATH:~/zig` ou similaire à votre `/etc/profile` (pour l'ensemble du système) ou `$HOME/.profile`. Si ces changements ne s'appliquent pas immédiatement, exécutez la ligne depuis votre interpréteur de commandes.
   - windows

      a) A l'échelle du système (admin powershell)

      ```Powershell
      [Environment]::SetEnvironmentVariable(
         "Path",
         [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\votre-chemin\zig-windows-x86_64-your-version",
         "Machine"
      )
      ```

      b) Niveau utilisateur (powershell)

      ```Powershell
      [Environment]::SetEnvironmentVariable(
         "Path",
         [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\votre-chemin\zig-windows-x86_64-your-version",
         "User"
      )
      ```

      Fermez votre terminal et créez-en un nouveau.

3. Vérifiez votre installation avec `zig version`. La sortie devrait ressembler à quelque chose comme
```
$ zig version
0.11.0-dev.2777+b95cdf0ae
```

4) (optionnel, tierce partie) Pour l'auto-complétion et le go-to-definition dans votre éditeur, installez le Zig Language Server à partir de :
```
https://github.com/zigtools/zls/
```
5) (facultatif) Rejoignez une [communauté Zig](https://github.com/ziglang/zig/wiki/Community).

# Hello World

Créez un fichier appelé `main.zig`, avec le contenu suivant :

```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello, {s}!\n", .{"World"});
}
```
###### (note : assurez-vous que votre fichier utilise des espaces pour l'indentation, des fins de ligne LF et l'encodage UTF-8 !)

Utilisez `zig run main.zig` pour le construire et l'exécuter. Dans cet exemple, `Hello, World!` sera écrit sur stderr, et est supposé ne jamais échouer.
