import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Repositories',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late String githubUsername;
  late List<Repository> repositories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GitHub Repositories'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Enter GitHub Username',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    fetchRepositories();
                  },
                ),
              ),
              onChanged: (value) {
                githubUsername = value;
              },
            ),
          ),
          Expanded(
            child: repositories.isNotEmpty
                ? ListView.builder(
                    itemCount: repositories.length,
                    itemBuilder: (context, index) {
                      var repo = repositories[index];
                      return Card(
                        elevation: 4, 
                        margin: EdgeInsets.all(12), 
                        child: GestureDetector(
                          onTap: () {
                            launch(repo.htmlUrl);
                          },
                          child: ListTile(
                            title: Text(("Repository -> ")+(repo.name)),
                            subtitle: Text("Latest Commit -> "+ (repo.lastCommitMessage ?? 'No commits')),
                          ),
                        ),
                      );
                    },
                  )
                : Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Future<void> fetchRepositories() async {
    try {
      final response = await http.get(Uri.parse('https://api.github.com/users/$githubUsername/repos'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        repositories = data.map((repo) => Repository.fromJson(repo)).toList();

        for (var repo in repositories) {
          await fetchLastCommit(repo);
        }

        setState(() {});
      } else {
        print('Failed to load repositories. Status code: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load repositories. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching repositories: $error');
    }
  }

  Future<void> fetchLastCommit(Repository repo) async {
    try {
      final response = await http.get(Uri.parse('https://api.github.com/repos/$githubUsername/${repo.name}/commits'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          repo.lastCommitSha = data[0]['sha'];
          repo.lastCommitMessage = data[0]['commit']['message'];
        }
      }
    } catch (error) {
      print('Error fetching last commit for ${repo.name}: $error');
    }
  }
}

class Repository {
  late final String name;
  late final String lastCommitSha;
  String? lastCommitMessage;
  late final String htmlUrl;

  Repository({
    required this.name,
    required this.htmlUrl,
  });

  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
      name: json['name'],
      htmlUrl: json['html_url'],
    );
  }
}
