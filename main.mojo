from std.ffi import external_call


def main():
    external_call["say_hello", NoneType]()
