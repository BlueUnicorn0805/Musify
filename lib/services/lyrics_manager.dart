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

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class LyricsManager {
  Future<String?> fetchLyrics(String artistName, String title) async {
    title = title.replaceAll('Lyrics', '').replaceAll('Karaoke', '');
    final lyricsFromParolesNet =
        await _fetchLyricsFromParolesNet(artistName, title);
    if (lyricsFromParolesNet != null) {
      return lyricsFromParolesNet;
    }

    final lyricsFromLyricsMania1 =
        await _fetchLyricsFromLyricsMania1(artistName, title);
    return lyricsFromLyricsMania1;
  }

  Future<String?> _fetchLyricsFromParolesNet(
    String artistName,
    String title,
  ) async {
    final uri = Uri.parse(
      'https://www.paroles.net/${_lyricsUrl(artistName)}/paroles-${_lyricsUrl(title)}',
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);
      final songTextElements = document.querySelectorAll('.song-text');

      if (songTextElements.isNotEmpty) {
        final lyricsLines = songTextElements.first.text.split('\n');
        if (lyricsLines.length > 1) {
          lyricsLines.removeAt(0);

          final finalLyrics =
              addCopyright(lyricsLines.join('\n'), '© www.paroles.net');
          return _removeSpaces(finalLyrics);
        }
      }
    }

    return null;
  }

  Future<String?> _fetchLyricsFromLyricsMania1(
    String artistName,
    String title,
  ) async {
    final uri = Uri.parse(
      'https://www.lyricsmania.com/${_lyricsManiaUrl(title)}_lyrics_${_lyricsManiaUrl(artistName)}.html',
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final document = html_parser.parse(response.body);
      final lyricsBodyElements = document.querySelectorAll('.lyrics-body');

      if (lyricsBodyElements.isNotEmpty) {
        return addCopyright(
          lyricsBodyElements.first.text,
          '© www.lyricsmania.com',
        );
      }
    }

    return null;
  }

  String _lyricsUrl(String input) {
    var result = input.replaceAll(' ', '-').toLowerCase();
    if (result.isNotEmpty && result.endsWith('-')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  String _lyricsManiaUrl(String input) {
    var result = input.replaceAll(' ', '_').toLowerCase();
    if (result.isNotEmpty && result.startsWith('_')) {
      result = result.substring(1);
    }
    if (result.isNotEmpty && result.endsWith('_')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  String _removeSpaces(String input) {
    return input.replaceAll('  ', '');
  }

  String addCopyright(String input, String copyright) {
    return '$input\n\nCopyright: $copyright';
  }
}
