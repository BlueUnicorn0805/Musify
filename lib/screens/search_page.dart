/*
 *     Copyright (C) 2024 Valeri Gokadze
 *
 *     Musify is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     Musify is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about Musify, including how to contribute,
 *     please visit: https://github.com/gokadzev/Musify
 */

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musify/API/musify.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/data_manager.dart';
import 'package:musify/widgets/confirmation_dialog.dart';
import 'package:musify/widgets/custom_search_bar.dart';
import 'package:musify/widgets/song_bar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

List searchHistory = Hive.box('user').get('searchHistory', defaultValue: []);

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchBar = TextEditingController();
  final FocusNode _inputNode = FocusNode();
  final ValueNotifier<bool> _fetchingSongs = ValueNotifier(false);
  List _searchResult = [];
  List _suggestionsList = [];

  @override
  void dispose() {
    _searchBar.dispose();
    _inputNode.dispose();
    super.dispose();
  }

  Future<void> search() async {
    final query = _searchBar.text;

    if (query.isEmpty) {
      _searchResult = [];
      _suggestionsList = [];
      setState(() {});
      return;
    }

    if (!_fetchingSongs.value) {
      _fetchingSongs.value = true;
    }

    if (!searchHistory.contains(query)) {
      searchHistory.insert(0, query);
      addOrUpdateData('user', 'searchHistory', searchHistory);
    }

    try {
      _searchResult = await fetchSongsList(query);
    } catch (e, stackTrace) {
      logger.log('Error while searching online songs', e, stackTrace);
    }

    if (_fetchingSongs.value) {
      _fetchingSongs.value = false;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.search),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            CustomSearchBar(
              loadingProgressNotifier: _fetchingSongs,
              controller: _searchBar,
              focusNode: _inputNode,
              labelText: '${context.l10n!.search}...',
              onChanged: (value) async {
                if (value.isNotEmpty) {
                  _suggestionsList = await getSearchSuggestions(value);
                } else {
                  _suggestionsList = [];
                }
                setState(() {});
              },
              onSubmitted: (String value) {
                search();
                _suggestionsList = [];
                _inputNode.unfocus();
              },
            ),
            if (_searchResult.isEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _suggestionsList.isEmpty
                    ? searchHistory.length
                    : _suggestionsList.length,
                itemBuilder: (BuildContext context, int index) {
                  final suggestionsNotAvailable = _suggestionsList.isEmpty;
                  final query = suggestionsNotAvailable
                      ? searchHistory[index]
                      : _suggestionsList[index];

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: const Icon(FluentIcons.search_24_regular),
                      title: Text(query),
                      onTap: () async {
                        _searchBar.text = query;
                        await search();
                        _inputNode.unfocus();
                      },
                      onLongPress: () async {
                        final confirm =
                            await _showConfirmationDialog(context) ?? false;

                        if (confirm) {
                          setState(() {
                            searchHistory.remove(query);
                          });

                          addOrUpdateData(
                            'user',
                            'searchHistory',
                            searchHistory,
                          );
                        }
                      },
                    ),
                  );
                },
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResult.length,
                itemBuilder: (BuildContext context, int index) {
                  return SongBar(
                    _searchResult[index],
                    true,
                    showMusicDuration: true,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          confirmationMessage: context.l10n!.removeSearchQueryQuestion,
          submitMessage: context.l10n!.confirm,
          onCancel: () {
            Navigator.of(context).pop(false);
          },
          onSubmit: () {
            Navigator.of(context).pop(true);
          },
        );
      },
    );
  }
}
