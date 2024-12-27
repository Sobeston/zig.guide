//! This module provides functions for dealing with spreadsheets.

const std = @import("std");

/// A spreadsheet position
pub const Pos = struct {
    /// (0-indexed) row
    x: u32,
    /// (0-indexed) column
    y: u32,

    /// The top-left position
    pub const zero: Pos = .{ .x = 0, .y = 0 };

    /// Illegal position
    pub const invalid_pos: Pos = .{
        .x = std.math.maxInt(u32),
        .y = std.math.maxInt(u32),
    };
};

pub const OpenFileError = error{
    /// Unexpected file extension
    InvalidSheet,
    FileNotFound,
};

pub const ParseError = error{
    /// File header invalid
    InvalidSheet,
    InvalidPosition,
};

pub const OpenError = OpenFileError || ParseError;

pub fn readCell(file: std.fs.File, pos: Pos) OpenError![]const u8 {
    _ = file;
    _ = pos;
    @panic("todo");
}
