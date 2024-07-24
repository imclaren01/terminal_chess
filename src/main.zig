const std = @import("std");
const debug = std.debug;
const testing = std.testing;
const Allocator = std.mem.Allocator;

const BOARD_WIDTH = 8;
const SQUARE_COUNT = BOARD_WIDTH * BOARD_WIDTH;

const Piece = enum(u4) {
    Empty = 0,
    WhitePawn = 1,
    WhiteBishop = 2,
    WhiteKnight = 3,
    WhiteRook = 4,
    WhiteQueen = 5,
    WhiteKing = 6,
    // We step up to 9 to allow for checking the color of a piece to be a simple bitwise operation
    BlackPawn = 9,
    BlackBishop = 10,
    BlackKnight = 11,
    BlackRook = 12,
    BlackQueen = 13,
    BlackKing = 14,

    pub fn isWhite(self: Piece) ?bool {
        return if (self == .Empty) null else (@intFromEnum(self) & 0b1000 == 0);
    }
    pub fn toUnicode(self: Piece) []const u8 {
        return switch (self) {
            .Empty => "·",
            .WhitePawn => "♟",
            .WhiteBishop => "♝",
            .WhiteKnight => "♞",
            .WhiteRook => "♜",
            .WhiteQueen => "♛",
            .WhiteKing => "♚",
            .BlackPawn => "♙",
            .BlackBishop => "♗",
            .BlackKnight => "♘",
            .BlackRook => "♖",
            .BlackQueen => "♕",
            .BlackKing => "♔",
        };
    }
};

pub const Board = struct {
    board: [SQUARE_COUNT]Piece = std.mem.zeroes([64]Piece),

    pub fn initializeDefaultBoard(self: *Board) void {
        const white_pieces = [_]Piece{ .WhiteRook, .WhiteKnight, .WhiteBishop, .WhiteQueen, .WhiteKing, .WhiteBishop, .WhiteKnight, .WhiteRook };
        const black_pieces = [_]Piece{ .BlackRook, .BlackKnight, .BlackBishop, .BlackQueen, .BlackKing, .BlackBishop, .BlackKnight, .BlackRook };

        // Set up white pieces
        @memcpy(self.board[0..8], &white_pieces);

        // Set up white pawns
        @memset(self.board[8..16], .WhitePawn);

        // Set up black pawns
        @memset(self.board[48..56], .BlackPawn);

        // Set up black pieces
        @memcpy(self.board[56..64], &black_pieces);
    }

    pub fn getPiece(self: *const Board, rank: usize, file: usize) Piece {
        std.debug.assert(rank < BOARD_WIDTH and file < BOARD_WIDTH);

        return self.board[rank * 8 + file];
    }

    pub fn getPieceByIndex(self: *const Board, index: usize) Piece {
        std.debug.assert(index < SQUARE_COUNT);

        return self.board[index];
    }

    pub fn format(self: *const Board, buffer: []u8) ![]const u8 {
        const board_width = 17; // 8 squares + 7 spaces + 2 border chars
        const board_height = 10; // 8 ranks + 2 border rows
        const total_size = (board_width + 1) * board_height + board_width + 1; // +1 for newlines, +board_width+1 for bottom label

        if (buffer.len < total_size) return error.BufferTooSmall;

        var fbs = std.io.fixedBufferStream(buffer);
        const writer = fbs.writer();

        try writer.writeAll("  a b c d e f g h\n");
        try writer.writeAll("+-+-+-+-+-+-+-+-+\n");

        for (0..8) |rank| {
            try writer.print("{d}|", .{8 - rank});
            for (0..8) |file| {
                const piece = self.getPiece(7 - rank, file);
                try writer.print("{s}", .{piece.toUnicode()});
                if (file < 7) {
                    try writer.writeByte(' ');
                }
            }
            try writer.print("|{d}\n", .{8 - rank});
        }

        try writer.writeAll("+-+-+-+-+-+-+-+-+\n");
        try writer.writeAll("  a b c d e f g h\n");

        return fbs.getWritten();
    }
};

pub fn main() !void {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    var board: Board = .{};
    board.initializeDefaultBoard();
    var boardBuffer: [256]u8 = undefined;

    while (true) {
        const formattedBoard = try board.format(&boardBuffer);
        defer boardBuffer.flush();
        try stdout.print("Current Board: {s}\n", .{formattedBoard});
        try stdout.print("Your move:", .{});
        var inputBuffer: [100]u8 = undefined;

        const input = try stdin.readUntilDelimiter(&inputBuffer, '\n');
        try stdout.print("{s}\n", .{input});
    }

    // // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    //
    // // stdout is for the actual output of your application, for example if you
    // // are implementing gzip, then only the compressed bytes should be sent to
    // // stdout, not any debugging messages.
    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();
    //
    // try stdout.print("Run `zig build test` to run the tests.\n", .{});
    //
    // try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "isWhite() test" {
    const whiteKnight = Piece.WhiteKnight;
    const blackBishop = Piece.BlackBishop;
    const empty = Piece.Empty;

    try testing.expect(whiteKnight.isWhite() orelse false);
    try testing.expect(!(blackBishop.isWhite() orelse true));
    try testing.expect(empty.isWhite() == null);
}
