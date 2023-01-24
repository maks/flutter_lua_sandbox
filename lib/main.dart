import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lua_dardo/lua.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 3;

  LuaState state = LuaState.newState();

  @override
  void initState() {
    super.initState();
    state.openLibs();
  }

  void _incrementCounter() {
    setState(() {
      const luaChunk = "x=x+1";
      debugPrint("Lua chunk: $luaChunk");
      state.loadString(luaChunk);
      state.pushInteger(_counter);
      state.setGlobal('x');

      // run the Lua chunk
      state.call(0, 0);

      // push value of the global `x` variable from Lua onto the Lua "C" stack
      // LuaDardo use the same "virtual stack API" as the official Lua VM uses to interface with C
      // more details see: http://www.lua.org/manual/5.1/manual.html#3.1
      final t = state.getGlobal("x");

      // check the type of the global value is a number like we expect
      if (t != LuaType.luaNumber) {
        debugPrint("err $t: ${state.toStr(-1)}");
        return;
      }

      // now get the actual value of `x` from Lua stack
      final result = state.toInteger(-1);
      //clear the Lua stack
      state.setTop(0);
      debugPrint("[${state.getTop()}] res:$result");

      // use the value we got from Lua
      _counter = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            ElevatedButton(
              onPressed: () => _callLuaFunction('testme'),
              child: const Text("Call Lua Function"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  int _printFromLua(LuaState ls) {
    final s = ls.checkString(1);
    ls.pop(1);
    debugPrint("DART FROM LUA: $s");
    return 1;
  }
  
  Future<void> _callLuaFunction(String s) async {
    final luaChunk = await rootBundle.loadString('assets/testme.lua');

    debugPrint("Lua chunk: $luaChunk");
    state.loadString(luaChunk);
    state.call(0, 0); // eval loaded chunk


    state.pushDartFunction(_printFromLua);
    state.setGlobal('dartPrint');

    final t = state.getGlobal("hello");

    if (t != LuaType.luaFunction) {
      debugPrint("type err, expected a function but got [$t] ${state.toStr(-1)}");
      return;
    }

    // run the Lua chunk
    final r = state.pCall(0, 1, 1);
    if (r != ThreadStatus.lua_ok) {
      debugPrint("Lua error calling function: ${state.toStr(-1)}");
      return;
    }

    // now get the actual value from Lua stack
    final reply = state.toStr(-1);
    //clear the Lua stack
    state.setTop(0);
    debugPrint("[${state.getTop()}] Lua fn result:$reply");
  }
}
