import 'package:flutter/material.dart';
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
    // TODO: implement initState
    super.initState();
    state.openLibs();
  }

  void _incrementCounter() {
    setState(() {
      const luaprg = "x=x+1";
      print("INc $luaprg");
      state.loadString(luaprg);
      state.pushInteger(_counter);
      state.setGlobal('x');
      state.call(0, 0);

      final t = state.getGlobal("x");
      if (t != LuaType.luaNumber) {
        print("err $t: ${state.toStr(-1)}");
        return;
      }
      // state.call(0, 0);
      final result = state.toInteger(-1);
      //clear the stack
      state.setTop(0);
      print("[${state.getTop()}] res:$result");
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
}
