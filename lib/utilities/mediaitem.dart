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

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

Map mediaItemToMap(MediaItem mediaItem) => {
      'id': mediaItem.id,
      'ytid': mediaItem.extras!['ytid'],
      'album': mediaItem.album.toString(),
      'artist': mediaItem.artist.toString(),
      'title': mediaItem.title,
      'highResImage': mediaItem.artUri.toString(),
      'lowResImage': mediaItem.extras!['lowResImage'],
      'url': mediaItem.extras!['url'].toString(),
      'isLive': mediaItem.extras!['isLive'],
    };

MediaItem mapToMediaItem(Map song, String songUrl) => MediaItem(
      id: song['id'].toString(),
      album: '',
      artist: song['artist'].toString(),
      title: song['title'].toString(),
      artUri: song['isOffline'] ?? false
          ? Uri.file(
              song['highResImage'].toString(),
            )
          : Uri.parse(
              song['highResImage'].toString(),
            ),
      extras: {
        'url': songUrl,
        'lowResImage': song['lowResImage'],
        'ytid': song['ytid'],
        'isLive': song['isLive'],
        'isOffline': song['isOffline'],
        'artWorkPath': song['highResImage'].toString(),
      },
    );

UriAudioSource createAudioSource(MediaItem mediaItem) => AudioSource.uri(
      Uri.parse(mediaItem.extras!['url'].toString()),
      tag: mediaItem,
    );

List<UriAudioSource> createAudioSources(List<MediaItem> mediaItems) {
  return mediaItems
      .map(
        (mediaItem) => AudioSource.uri(
          Uri.parse(mediaItem.extras!['url'].toString()),
          tag: mediaItem,
        ),
      )
      .toList();
}
