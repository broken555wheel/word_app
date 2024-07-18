import 'dart:ffi';

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Word App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var wordPairs = <WordPair>[];
  WordPair? searchedPair;
  
  void getNext() {
    current = WordPair.random();
    wordPairs.add(current);
    notifyListeners(); // notifies listeners that the state of the object has changed, triggers rebuild widgets
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  void getPrevious() {
    var currentIndex = wordPairs.indexOf(current);
    if (currentIndex > 0) {
      current = wordPairs[currentIndex - 1];
    }
    notifyListeners();
  }

  void deleteFavorite(WordPair wordPair) {
    favorites.remove(wordPair);
    notifyListeners();
  }

  void searchFavorites(WordPair wordPair) {
    searchedPair = favorites.contains(wordPair) ? wordPair : null;
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      case 1:
        page = FavoritesPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                backgroundColor: Color.fromARGB(97, 77, 75, 75),
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.favorite),
                    label: Text('Favorites'),
                  ),
                ],
                selectedLabelTextStyle: TextStyle(
                  color: Color.fromARGB(115, 182, 22, 22),
                  fontWeight: FontWeight.bold,
                ),
                selectedIconTheme: IconThemeData(
                  color: Color.fromARGB(115, 182, 22, 22),
                  weight: 10,
                ),
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                  onPressed: () {
                    appState.getPrevious();
                  },
                  child: Text('Previous')),
              SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
      fontStyle: FontStyle.italic,
      letterSpacing: 3.0,
    );
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(pair.asLowerCase,
            style: style, semanticsLabel: "${pair.first} ${pair.second}"),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.favorites.length} favorites:'),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: 250,
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Enter a pair of words',
                  ),
                ),
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton(
                onPressed: () {
                  List<String> stringPair = _controller.text.split(' ');
                  WordPair enteredText = WordPair(stringPair[0], stringPair[1]);
                  appState.searchFavorites(enteredText);
                },
                child: Icon(Icons.search))
          ],
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: ElevatedButton(
                onPressed: () {
                  appState.deleteFavorite(pair);
                },
                child: Icon(Icons.delete)),
            title: ConditionalText(pair: pair),
            
          ),
      ],
    );
  }
}

class ConditionalText extends StatelessWidget {
  const ConditionalText({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Text(pair.asLowerCase,
    textScaler:appState.searchedPair == pair? TextScaler.linear(2) : null,
    );
  }
}
