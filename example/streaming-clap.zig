const clap = @import("clap");
const std = @import("std");

const debug = std.debug;
const io = std.io;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // First we specify what parameters our program can take.
    const params = [_]clap.Param(u8){
        .{
            .id = 'h',
            .names = .{ .short = 'h', .long = "help" },
        },
        .{
            .id = 'n',
            .names = .{ .short = 'n', .long = "number" },
            .takes_value = .one,
        },
        .{ .id = 'f', .takes_value = .one },
    };

    // We then initialize an argument iterator. We will use the OsIterator as it nicely
    // wraps iterating over arguments the most efficient way on each os.
    var iter = try clap.args.OsIterator.init(allocator);
    defer iter.deinit();

    // Initalize our diagnostics, which can be used for reporting useful errors.
    // This is optional. You can also leave the `diagnostic` field unset if you
    // don't care about the extra information `Diagnostic` provides.
    var diag = clap.Diagnostic{};
    var parser = clap.StreamingClap(u8, clap.args.OsIterator){
        .params = &params,
        .iter = &iter,
        .diagnostic = &diag,
    };

    // Because we use a streaming parser, we have to consume each argument parsed individually.
    while (parser.next() catch |err| {
        // Report useful error and exit
        diag.report(io.getStdErr().writer(), err) catch {};
        return err;
    }) |arg| {
        // arg.param will point to the parameter which matched the argument.
        switch (arg.param.id) {
            'h' => debug.print("Help!\n", .{}),
            'n' => debug.print("--number = {s}\n", .{arg.value.?}),

            // arg.value == null, if arg.param.takes_value == .none.
            // Otherwise, arg.value is the value passed with the argument, such as "-a=10"
            // or "-a 10".
            'f' => debug.print("{s}\n", .{arg.value.?}),
            else => unreachable,
        }
    }
}
