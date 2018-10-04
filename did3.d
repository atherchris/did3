/*
 * Copyright (c) 2018, Christopher Atherton <the8lack8ox@gmail.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
 
import std.encoding;
import std.getopt;

import std.algorithm : all, countUntil, min;
import std.bitmanip : nativeToBigEndian;
import std.conv : to;
import std.datetime;
import std.exception : enforce;
import std.file;
import std.path : baseName;
import std.stdio : stderr, writeln;

immutable string ERROR_STR_EOF = "Unexpected end of file!";

immutable string[256] ID3V1_GENRES =
[
	"Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk", "Grunge",
	"Hip-Hop", "Jazz", "Metal", "New Age", "Oldies", "Other", "Pop", "R&B",
	"Rap", "Reggae", "Rock", "Techno", "Industrial", "Alternative", "Ska",
	"Death Metal", "Pranks", "Soundtrack", "Euro-Techno", "Ambient",
	"Trip-Hop", "Vocal", "Jazz+Funk", "Fusion", "Trance", "Classical",
	"Instrumental", "Acid", "House", "Game", "Sound Clip", "Gospel", "Noise",
	"AlternRock", "Bass", "Soul", "Punk", "Space", "Meditative",
	"Instrumental Pop", "Instrumental Rock", "Ethnic", "Gothic", "Darkwave",
	"Techno-Industrial", "Electronic", "Pop-Folk", "Eurodance", "Dream",
	"Southern Rock", "Comedy", "Cult", "Gangsta", "Top 40", "Christian Rap",
	"Pop/Funk", "Jungle", "Native American", "Cabaret", "New Wave",
	"Psychadelic", "Rave", "Showtunes", "Trailer", "Lo-Fi", "Tribal",
	"Acid Punk", "Acid Jazz", "Polka", "Retro", "Musical", "Rock & Roll",
	"Hard Rock", "Folk", "Folk-Rock", "National Folk", "Swing", "Fast Fusion",
	"Bebob", "Latin", "Revival", "Celtic", "Bluegrass", "Avantgarde",
	"Gothic Rock", "Progressive Rock", "Psychedelic Rock", "Symphonic Rock",
	"Slow Rock", "Big Band", "Chorus", "Easy Listening", "Acoustic", "Humour",
	"Speech", "Chanson", "Opera", "Chamber Music", "Sonata", "Symphony",
	"Booty Bass", "Primus", "Porn Groove", "Satire", "Slow Jam", "Club",
	"Tango", "Samba", "Folklore", "Ballad", "Power Ballad", "Rhythmic Soul",
	"Freestyle", "Duet", "Punk Rock", "Drum Solo", "A capella", "Euro-House",
	"Dance Hall", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown", "Unknown",
	"Unknown", "Unknown", "Unknown", "Unknown", "Unknown"
];

immutable uint ID3V2_SYNCWORD		= 0x49443302;	// ID3\x02
immutable uint ID3V3_SYNCWORD		= 0x49443303;	// ID3\x03
immutable uint ID3V4_SYNCWORD		= 0x49443304;	// ID3\x04

immutable uint ID3V2_TITLE_FID		= 0x545432;		// TT2
immutable uint ID3V2_ARTIST_FID		= 0x545031;		// TP1
immutable uint ID3V2_PERFORMER_FID	= 0xFFFFFFFF;
immutable uint ID3V2_ALBUM_FID		= 0x54414C;		// TAL
immutable uint ID3V2_TRACK_FID		= 0x54524B;		// TRK
immutable uint ID3V2_DISC_FID		= 0x545041;		// TPA
immutable uint ID3V2_GENRE_FID		= 0x54434F;		// TCO
immutable uint ID3V2_YEAR_FID		= 0x545945;		// TYE
immutable uint ID3V2_COMMENT_FID	= 0x434F4D;		// COM
immutable uint ID3V2_COVER_FID		= 0x504943;		// PIC

immutable uint ID3V3_TITLE_FID		= 0x54495432;	// TIT2
immutable uint ID3V3_ARTIST_FID		= 0x54504531;	// TPE1
immutable uint ID3V3_PERFORMER_FID	= 0xFFFFFFFF;
immutable uint ID3V3_ALBUM_FID		= 0x54414C42;	// TALB
immutable uint ID3V3_TRACK_FID		= 0x5452434B;	// TRCK
immutable uint ID3V3_DISC_FID		= 0x54504F53;	// TPOS
immutable uint ID3V3_GENRE_FID		= 0x54434F4E;	// TCON
immutable uint ID3V3_YEAR_FID		= 0x54594552;	// TYER
immutable uint ID3V3_COMMENT_FID	= 0x434F4D4D;	// COMM
immutable uint ID3V3_COVER_FID		= 0x41504943;	// APIC

immutable uint ID3V4_TIMESTAMP_FID	= 0x54445447;	// TDTG

struct Tag
{
	string title;
	string artist;
	string performer;
	string album;
	uint track;
	uint disc;
	string genre;
	uint year;
	string comment;
	immutable( ubyte )[] cover;

	bool removeTitle;
	bool removeArtist;
	bool removePerformer;
	bool removeAlbum;
	bool removeTrack;
	bool removeDisc;
	bool removeGenre;
	bool removeYear;
	bool removeComment;
	bool removeCover;

	string timestamp;

	@property bool empty()
	{
		return title.length == 0
			&& performer.length == 0
			&& album.length == 0
			&& track == 0
			&& disc == 0
			&& genre.length == 0
			&& year == 0
			&& comment.length == 0
			&& cover.length == 0
			&& ! removeTitle
			&& ! removeArtist
			&& ! removePerformer
			&& ! removeAlbum
			&& ! removeTrack
			&& ! removeDisc
			&& ! removeGenre
			&& ! removeYear
			&& ! removeComment
			&& ! removeCover;
	}

	Tag update( in Tag other )
	{
		if( other.title.length > 0 )
		{
			title = other.title;
			removeTitle = false;
		}
		else if( other.removeTitle )
		{
			title = title.init;
			removeTitle = true;
		}

		if( other.artist.length > 0 )
		{
			artist = other.artist;
			removeArtist = false;
		}
		else if( other.removeArtist )
		{
			artist = artist.init;
			removeArtist = true;
		}

		if( other.performer.length > 0 )
		{
			performer = other.performer;
			removePerformer = false;
		}
		else if( other.removePerformer )
		{
			performer = performer.init;
			removePerformer = true;
		}

		if( other.album.length > 0 )
		{
			album = other.album;
			removeAlbum = false;
		}
		else if( other.removeAlbum )
		{
			album = album.init;
			removeAlbum = true;
		}

		if( other.track > 0 )
		{
			track = other.track;
			removeTrack = false;
		}
		else if( other.removeTrack )
		{
			track = track.init;
			removeTrack = true;
		}

		if( other.disc > 0 )
		{
			disc = other.disc;
			removeDisc = false;
		}
		else if( other.removeDisc )
		{
			disc = disc.init;
			removeDisc = true;
		}

		if( other.genre.length > 0 )
		{
			genre = other.genre;
			removeGenre = false;
		}
		else if( other.removeGenre )
		{
			genre = genre.init;
			removeGenre = true;
		}

		if( other.year > 0 )
		{
			year = other.year;
			removeYear = false;
		}
		else if( other.removeYear )
		{
			year = year.init;
			removeYear = true;
		}

		if( other.comment.length > 0 )
		{
			comment = other.comment;
			removeComment = false;
		}
		else if( other.removeComment )
		{
			comment = comment.init;
			removeComment = true;
		}

		if( other.cover.length > 0 )
		{
			cover = other.cover.dup;
			removeCover = false;
		}
		else if( other.removeCover )
		{
			cover = cover.init;
			removeCover = true;
		}

		//timestamp = other.timestamp;

		return this;
	}
}

immutable( ubyte )[] encodeSynchSafeInt( uint n ) pure
{
	return
	[
		cast( ubyte )( ( n & 0x0FE00000 ) >> 21 ),
		cast( ubyte )( ( n & 0x001FC000 ) >> 14 ),
		cast( ubyte )( ( n & 0x00003F80 ) >> 7 ),
		cast( ubyte )( n & 0x0000007F )
	];
}

uint readId3Int( ref immutable( ubyte )[] buffer, size_t len, bool synch = false ) pure
{
	enforce( buffer.length >= len, ERROR_STR_EOF );

	uint ret;
	foreach( size_t i, uint c; buffer[0 .. len] )
	{
		if( synch )
		{
			enforce( ! ( c & 0x80 ), "Bad synchsafe integer" );
			ret |= c << ( 7 * ( len - i - 1 ) );
		}
		else
		{
			ret |= c << ( 8 * ( len - i - 1 ) );
		}
	}

	buffer = buffer[len .. $];

	return ret;
}

string readId3Text( ref immutable( ubyte )[] buffer, uint encoding )
{
	string ret;

	switch( encoding )
	{
		case 0:
		case 3:
			long len = countUntil( buffer, "\x00" );
			if( len == -1 )
			{
				ret = cast( string )buffer;
				buffer = buffer[$ .. $];
			}
			else
			{
				ret = cast( string )buffer[0 .. len];
				buffer = buffer[len+1 .. $];
			}
			break;
		case 1:
		case 2:
			wchar[] tmp;
			long len = countUntil( buffer, "\x00\x00" );
			enforce( buffer.length >= 2, ERROR_STR_EOF );
			if( buffer[0] == 0xFE && buffer[1] == 0xFF )
			{
				if( len == -1 )
				{
					version( BigEndian )
					{
						tmp = buffer[wchar.sizeof .. $];
						buffer = buffer[$ .. $];
					}
					version( LittleEndian )
					{
						tmp = new wchar[buffer.length-wchar.sizeof];
						foreach( size_t i, wchar c; buffer[wchar.sizeof .. $] )
						{
							tmp[i] = ( ( 0xFF00 & c ) >> 8 ) | ( ( 0x00FF & c ) << 8 );
						}
						buffer = buffer[$ .. $];
					}
				}
				else
				{
					version( BigEndian )
					{
						tmp = buffer[wchar.sizeof .. len];
						buffer = buffer[len+2 .. $];
					}
					version( LittleEndian )
					{
						tmp = new wchar[len-wchar.sizeof];
						foreach( size_t i, wchar c; buffer[wchar.sizeof .. len] )
						{
							tmp[i] = ( ( 0xFF00 & c ) >> 8 ) | ( ( 0x00FF & c ) << 8 );
						}
						buffer = buffer[len+2 .. $];
					}
				}
			}
			else if( buffer[0] == 0xFF && buffer[1] == 0xFE )
			{
				if( len == -1 )
				{
					version( BigEndian )
					{
						tmp = new wchar[buffer.length-wchar.sizeof];
						foreach( size_t i, wchar c; buffer[wchar.sizeof .. $] )
						{
							tmp[i] = ( ( 0xFF00 & c ) >> 8 ) | ( ( 0x00FF & c ) << 8 );
						}
						buffer = buffer[$ .. $];
					}
					version( LittleEndian )
					{
						tmp = cast( wchar[] )( buffer[wchar.sizeof .. $] );
						buffer = buffer[$ .. $];
					}
				}
				else
				{
					version( BigEndian )
					{
						tmp = new wchar[len-wchar.sizeof];
						foreach( size_t i, wchar c; buffer[wchar.sizeof .. len] )
						{
							tmp[i] = ( ( 0xFF00 & c ) >> 8 ) | ( ( 0x00FF & c ) << 8 );
						}
						buffer = buffer[len+2 .. $];
					}
					version( LittleEndian )
					{
						tmp = cast( wchar[] )( buffer[wchar.sizeof .. len] );
						buffer = buffer[len+2 .. $];
					}
				}
			}
			else
			{
				if( len == -1 )
				{
					tmp = cast( wchar[] )buffer[0 .. $];
					buffer = buffer[$ .. $];
				}
				else
				{
					tmp = cast( wchar[] )buffer[0 .. len];
					buffer = buffer[len+2 .. $];
				}
			}
			transcode( tmp.idup, ret );
			break;
		default:
			throw new Exception( "Unknown text encoding!" );
	}

	return ret;
}

Tag readId3v1Tag( in immutable( ubyte )[] file )
{
	Tag ret;

	if( file.length >= 128 && file[$-128 .. $-125] == "TAG" )
	{
		immutable( ubyte )[] titleLastSixty;
		immutable( ubyte )[] artistLastSixty;
		immutable( ubyte )[] albumLastSixty;

		if( file.length >= 355 && file[$-355 .. $-351] == "TAG+" )
		{
			titleLastSixty = file[$-351 .. $-291];
			artistLastSixty = file[$-291 .. $-231];
			albumLastSixty = file[$-231 .. $-171];

			immutable( ubyte )[] genre = file[$-170 .. $-140];
			transcode( cast( AsciiString )genre[0 .. min( countUntil( genre, '\x00' ), 30 )], ret.genre );
		}

		immutable( ubyte )[] title = file[$-125 .. $-95] ~ titleLastSixty;
		immutable( ubyte )[] artist = file[$-95 .. $-65] ~ artistLastSixty;
		immutable( ubyte )[] album = file[$-65 .. $-35] ~ albumLastSixty;

		size_t titleLen = countUntil( title, '\x00' );
		if( titleLen == -1 )
			titleLen = title.length;
		size_t artistLen = countUntil( artist, '\x00' );
		if( artistLen == -1 )
			artistLen = artist.length;
		size_t albumLen = countUntil( album, '\x00' );
		if( albumLen == -1 )
			albumLen = album.length;

		transcode( cast( AsciiString )title[0 .. titleLen], ret.title );
		transcode( cast( AsciiString )artist[0 .. artistLen], ret.artist );
		transcode( cast( AsciiString )album[0 .. albumLen], ret.album );

		if( all( file[$-35 .. $-31] ) )
		{
			string yearStr;
			transcode( cast( AsciiString )file[$-35 .. $-31], yearStr );
			ret.year = to!uint( yearStr );
		}

		if( file[$-3] == 0 )
		{
			immutable( ubyte )[] comment = file[$-31 .. $-3];
			auto commentLen = countUntil( comment, '\x00' );
			if( commentLen == -1 )
				commentLen = 28;
			transcode( cast( AsciiString )comment[0 .. commentLen], ret.comment );
			ret.track = file[$-2];
		}
		else if( file[$-3] > 0x7F )
		{
			immutable( ubyte )[] comment = file[$-31 .. $-3];
			auto commentLen = countUntil( comment, '\x00' );
			if( commentLen == -1 )
				commentLen = 28;
			transcode( cast( AsciiString )comment[0 .. commentLen], ret.comment );
		}
		else
		{
			immutable( ubyte )[] comment = file[$-31 .. $-1];
			auto commentLen = countUntil( comment, '\x00' );
			if( commentLen == -1 )
				commentLen = 30;
			transcode( cast( AsciiString )comment[0 .. commentLen], ret.comment );
		}

		if( ret.genre.length == 0 )
			ret.genre = ID3V1_GENRES[file[$-1]];
	}

	return ret;
}

Tag readId3v2Tag( in immutable( ubyte )[] file )
{
	Tag ret;
	immutable( ubyte )[] pos = file;

	// Universal ID3v2 header
	uint magic = readId3Int( pos, 4 );
	enforce( readId3Int( pos, 1 ) == 0, "Unknown ID3 version" );
	uint flags = readId3Int( pos, 1 );
	uint totalLen = readId3Int( pos, 4, true );
	pos = pos[0 .. totalLen];

	if( magic == ID3V2_SYNCWORD )
	{ // ID3v2.2
		while( pos.length > 9 && pos[0] != 0 )
		{
			uint frameId = readId3Int( pos, 3 );
			uint frameLen = readId3Int( pos, 3 );

			enforce( pos.length >= frameLen, ERROR_STR_EOF );

			immutable( ubyte )[] sub = pos[0 .. frameLen];
			pos = pos[frameLen .. $];

			switch( frameId )
			{
				case ID3V2_TITLE_FID:
					uint enc = readId3Int( sub, 1 );
					ret.title = readId3Text( sub, enc );
					break;
				case ID3V2_ARTIST_FID:
					uint enc = readId3Int( sub, 1 );
					ret.artist = readId3Text( sub, enc );
					break;
				case ID3V2_ALBUM_FID:
					uint enc = readId3Int( sub, 1 );
					ret.album = readId3Text( sub, enc );
					break;
				case ID3V2_TRACK_FID:
					uint enc = readId3Int( sub, 1 );
					ret.track = to!uint( readId3Text( sub, enc ) );
					break;
				case ID3V2_DISC_FID:
					uint enc = readId3Int( sub, 1 );
					ret.disc = to!uint( readId3Text( sub, enc ) );
					break;
				case ID3V2_GENRE_FID:
					// TODO Parse numbers
					uint enc = readId3Int( sub, 1 );
					ret.genre = readId3Text( sub, enc );
					break;
				case ID3V2_YEAR_FID:
					uint enc = readId3Int( sub, 1 );
					ret.year = to!uint( readId3Text( sub, enc ) );
					break;
				case ID3V2_COMMENT_FID:
					uint enc = readId3Int( sub, 1 );		// Encoding
					readId3Int( sub, 3 );					// Language
					readId3Text( sub, enc );				// Content description
					ret.comment = readId3Text( sub, enc );	// Comment
					break;
				case ID3V2_COVER_FID:
					uint enc = readId3Int( sub, 1 );		// Encoding
					readId3Int( sub, 3 );					// Image format
					readId3Int( sub, 1 );					// Type
					readId3Text( sub, enc );				// Description
					ret.cover = sub.idup;					// Picture data
					break;
				default:
					break;
			}
		}
	}
	else if( magic == ID3V3_SYNCWORD || magic == ID3V4_SYNCWORD )
	{ // ID3v2.3 or ID3v2.4
		// Extended header
		if( flags & 0x40 )
		{
			enforce( 10 <= pos.length, ERROR_STR_EOF );
			uint extLen = readId3Int( pos, 4, true );
			enforce( extLen <= pos.length, ERROR_STR_EOF );
			pos = pos[extLen .. $];
		}

		// Frames
		while( pos.length > 10 && pos[0] != 0 )
		{
			uint frameId = readId3Int( pos, 4 );
			uint frameLen = readId3Int( pos, 4 );
			uint frameFlags = readId3Int( pos, 2 );

			enforce( pos.length >= frameLen, ERROR_STR_EOF );

			immutable( ubyte )[] sub = pos[0 .. frameLen];
			pos = pos[frameLen .. $];

			switch( frameId )
			{
				case ID3V3_TITLE_FID:
					uint enc = readId3Int( sub, 1 );
					ret.title = readId3Text( sub, enc );
					break;
				case ID3V3_ARTIST_FID:
					uint enc = readId3Int( sub, 1 );
					ret.artist = readId3Text( sub, enc );
					break;
				case ID3V3_ALBUM_FID:
					uint enc = readId3Int( sub, 1 );
					ret.album = readId3Text( sub, enc );
					break;
				case ID3V3_TRACK_FID:
					uint enc = readId3Int( sub, 1 );
					string trackStr = readId3Text( sub, enc );
					auto len = countUntil( trackStr, '/' );
					if( len == -1 )
						ret.track = to!uint( trackStr );
					else
						ret.track = to!uint( trackStr[0 .. len] );
					break;
				case ID3V3_DISC_FID:
					uint enc = readId3Int( sub, 1 );
					string discStr = readId3Text( sub, enc );
					auto len = countUntil( discStr, '/' );
					if( len == -1 )
						ret.disc = to!uint( discStr );
					else
						ret.disc = to!uint( discStr[0 .. len] );
					break;
				case ID3V3_GENRE_FID:
					uint enc = readId3Int( sub, 1 );
					ret.genre = readId3Text( sub, enc  );
					break;
				case ID3V3_YEAR_FID:
					uint enc = readId3Int( sub, 1 );
					ret.year = to!uint( readId3Text( sub, enc ) );
					break;
				case ID3V3_COMMENT_FID:
					uint enc = readId3Int( sub, 1 );		// Encoding
					readId3Int( sub, 3 );					// Language
					readId3Text( sub, enc );				// Content description
					ret.comment = readId3Text( sub, enc );	// Comment
					break;
				case ID3V3_COVER_FID:
					uint enc = readId3Int( sub, 1 );		// Encoding
					readId3Text( sub, 0 );					// MIME
					readId3Int( sub, 1 );					// Picture type
					readId3Text( sub, enc );				// Description
					ret.cover = sub.idup;					// Picture data
					break;
				case ID3V4_TIMESTAMP_FID:
					uint enc = readId3Int( sub, 1 );
					ret.timestamp = readId3Text( sub, enc );
					break;
				default:
					break;
			} // /FrameType
		} // /FrameLoop
	} // /ID3Ver

	return ret;
}

void stripId3v1Tag( ref immutable( ubyte )[] file ) pure
{
	if( file.length >= 355 )
	{
		if( file[$-128 .. $-125] == "TAG" )
		{
			if( file[$-355 .. $-351] == "TAG+" )
				file = file[0 .. $-355];
			else
				file = file[0 .. $-128];
		}
	}
	else if( file.length >= 128 )
	{
		if( file[$-128 .. $-125] == "TAG" )
			file = file[0 .. $-128];
	}
}

void stripId3v2Tag( ref immutable( ubyte )[] file ) pure
{
	if( file.length >= 10 )
	{
		if( readId3Int( file, 3 ) == 0x494433 )
		{
			uint ver = readId3Int( file, 1 );
			enforce( readId3Int( file, 1 ) == 0, "Unknown ID3 version" );
			if( ver == 2 || ver == 3 )
			{
				readId3Int( file, 1 );		// flags
				uint len = readId3Int( file, 4, true );
				enforce( len <= file.length, ERROR_STR_EOF );
				file = file[len .. $];
			}
			else if( ver == 4 )
			{
				uint flags = readId3Int( file, 1 );
				uint len = readId3Int( file, 4, true );
				if( flags & 0x10 )
				{
					enforce( len + 10 <= file.length );
					file = file[len+10 .. $];
				}
				else
				{
					enforce( len <= file.length, ERROR_STR_EOF );
					file = file[len .. $];
				}
			}
		}
	}
}

ubyte[] writeId3v2Tag( ref Tag tag )
{
	immutable ubyte[2] ZERO_FLAGS = [ 0, 0 ];

	immutable ubyte[1] LATIN1_TEXT = [ 0 ];
	immutable ubyte[1] UTF8_TEXT = [ 3 ];

	immutable ubyte[1] ONE_ZERO  = [ 0 ];
	immutable ubyte[2] TWO_ZEROS = [ 0, 0 ];

	immutable ubyte[3] COMM_UND = [ 0x75, 0x6E, 0x64 ];

	uint totalLen;

	// TIT2 -- title
	ubyte[] titleFrame;
	if( tag.title.length > 0 )
	{
		titleFrame = nativeToBigEndian( ID3V3_TITLE_FID )
			~ nativeToBigEndian( 1 + cast( uint )tag.title.length )
			~ ZERO_FLAGS ~ UTF8_TEXT ~ cast( ubyte[] )tag.title;
		totalLen += titleFrame.length;
	}

	// TPE1 -- artist
	ubyte[] artistFrame;
	if( tag.artist.length > 0 )
	{
		artistFrame = nativeToBigEndian( ID3V3_ARTIST_FID )
			~ nativeToBigEndian( 1 + cast( uint )tag.artist.length )
			~ ZERO_FLAGS ~ UTF8_TEXT ~ cast( ubyte[] )tag.artist;
		totalLen += artistFrame.length;
	}

/+
	// TPE1 -- artist
	ubyte[] performerFrame;
	if( tag.performer.length > 0 )
	{
		performerFrame = nativeToBigEndian( ID3V3_PERFORMER_FID )
			~ nativeToBigEndian( 1 + cast( uint )tag.artist.length )
			~ ZERO_FLAGS ~ UTF8_TEXT ~ cast( ubyte[] )tag.performer;
		totalLen += performerFrame.length;
	}
+/

	// TALB -- album
	ubyte[] albumFrame;
	if( tag.album.length > 0 )
	{
		albumFrame = nativeToBigEndian( ID3V3_ALBUM_FID )
			~ nativeToBigEndian( 1 + cast( uint )tag.album.length )
			~ ZERO_FLAGS ~ UTF8_TEXT ~ cast( ubyte[] )tag.album;
		totalLen += albumFrame.length;
	}

	// TRCK -- track#
	ubyte[] trackFrame;
	if( tag.track > 0 )
	{
		string str = to!string( tag.track );
		trackFrame = nativeToBigEndian( ID3V3_TRACK_FID )
			~ nativeToBigEndian( 1 + cast( uint )str.length )
			~ ZERO_FLAGS ~ UTF8_TEXT ~ cast( ubyte[] )str;
		totalLen += trackFrame.length;
	}

	// TPOS -- disc#
	ubyte[] discFrame;
	if( tag.disc > 0 )
	{
		string str = to!string( tag.disc );
		discFrame = nativeToBigEndian( ID3V3_DISC_FID )
			~ nativeToBigEndian( 1 + cast( uint )str.length )
			~ ZERO_FLAGS ~ UTF8_TEXT ~ cast( ubyte[] )str;
		totalLen += discFrame.length;
	}

	// TCON -- genre
	ubyte[] genreFrame;
	if( tag.genre.length > 0 )
	{
		genreFrame = nativeToBigEndian( ID3V3_GENRE_FID )
			~ nativeToBigEndian( 1 + cast( uint )tag.genre.length )
			~ ZERO_FLAGS ~ UTF8_TEXT ~ cast( ubyte[] )tag.genre;
		totalLen += genreFrame.length;
	}

	// TYER -- year
	ubyte[] yearFrame;
	if( tag.year > 0 )
	{
		string str = to!string( tag.year );
		yearFrame = nativeToBigEndian( ID3V3_YEAR_FID )
			~ nativeToBigEndian( 1 + cast( uint )str.length )
			~ ZERO_FLAGS ~ UTF8_TEXT ~ cast( ubyte[] )str;
		totalLen += yearFrame.length;
	}

	// COMM -- comment
	ubyte[] commentFrame;
	if( tag.comment.length > 0 )
	{
		commentFrame = nativeToBigEndian( ID3V3_COMMENT_FID )
			~ nativeToBigEndian( 5 + cast( uint )tag.comment.length )
			~ ZERO_FLAGS ~ UTF8_TEXT ~ COMM_UND ~ ONE_ZERO
			~ cast( ubyte[] )tag.comment;
		totalLen += commentFrame.length;
	}

	// APIC -- cover art
	ubyte[] coverFrame;
	if( tag.cover.length > 0 )
	{
		immutable( ubyte )[] COVER_PICTURE = [ cast( ubyte )3 ];
		coverFrame = nativeToBigEndian( ID3V3_COVER_FID )
			~ nativeToBigEndian( cast( uint )( 4 + tag.cover.length ) )
			~ ZERO_FLAGS ~ UTF8_TEXT ~ ONE_ZERO ~ COVER_PICTURE ~ ONE_ZERO
			~ tag.cover;
		totalLen += coverFrame.length;
	}

	// TDTG -- time stamp
	tag.timestamp = Clock.currTime( UTC() ).toISOExtString();
	ubyte[] timestampFrame = nativeToBigEndian( ID3V4_TIMESTAMP_FID )
		~ nativeToBigEndian( cast( uint )( 1 + tag.timestamp.length ) )
		~ ZERO_FLAGS ~ UTF8_TEXT ~ cast( ubyte[] )tag.timestamp;
	totalLen += timestampFrame.length;

	return nativeToBigEndian( ID3V4_SYNCWORD ) ~ TWO_ZEROS
		~ encodeSynchSafeInt( totalLen )
		~ titleFrame ~ artistFrame ~ albumFrame
		~ trackFrame ~ discFrame ~ genreFrame
		~ yearFrame ~ commentFrame ~ coverFrame
		~ timestampFrame;
}

int main( string[] args )
{
	int exitStatus = 0;

	try
	{
		Tag newTag;
		bool discardOldTag;
		string coverArtPath;
		string exportCoverArtPath;

		auto helpInfo = getopt
		(
			args,
			std.getopt.config.caseSensitive,
			"discard|r", "Remove all previous tag data.", &discardOldTag,

			"title|t", "Set title.", &newTag.title,
			"artist|a", "Set artist.", &newTag.artist,
			"performer|p", "Set performer.", &newTag.performer,
			"album|l", "Set album.", &newTag.album,
			"track|n", "Set track number.", &newTag.track,
			"disc|m", "Set disc number.", &newTag.disc,
			"genre|g", "Set genre.", &newTag.genre,
			"year|y", "Set year.", &newTag.year,
			"comment|c", "Set comment.", &newTag.comment,
			"cover|f", "Set cover art.", &coverArtPath,

			"remove-title|T", "Delete existing title.", &newTag.removeTitle,
			"remove-artist|A", "Delete existing artist.", &newTag.removeArtist,
			"remove-performer|P", "Delete existing performer.", &newTag.removePerformer,
			"remove-album|L", "Delete existing album.", &newTag.removeAlbum,
			"remove-track|N", "Delete existing track number.", &newTag.removeTrack,
			"remove-disc|M", "Delete existing disc number.", &newTag.removeDisc,
			"remove-genre|G", "Delete existing genre.", &newTag.removeGenre,
			"remove-year|Y", "Delete existing year.", &newTag.removeYear,
			"remove-comment|C", "Delete existing comment.", &newTag.removeComment,
			"remove-cover|F", "Delete existing cover art.", &newTag.removeCover,

			"export-cover|e", "Export existing cover art.", &exportCoverArtPath
		);

		if( helpInfo.helpWanted )
		{
			defaultGetoptPrinter( "MP3 ID3 tag editor", helpInfo.options );
			return 0;
		}

		if( coverArtPath.length > 0 )
		{
			newTag.cover = cast( immutable( ubyte )[] )read( coverArtPath );
		}

		// Process input(s)
		foreach( arg; args[1 .. $] )
		{
			try
			{
				// Get old tag
				Tag tag;
				immutable( ubyte )[] file = cast( immutable( ubyte )[] )read( arg );
				if( ! discardOldTag )
				{
					tag = readId3v1Tag( file );
					tag.update( readId3v2Tag( file ) );
				}

				// Export cover art
				if( exportCoverArtPath.length > 0 )
					std.file.write( exportCoverArtPath, tag.cover );

				// Check for tag alteration
				if( ! newTag.empty || discardOldTag )
				{
					// Remove old tag
					stripId3v2Tag( file );
					stripId3v1Tag( file );

					// Insert new tag fields
					tag.update( newTag );

					// Update file
					std.file.write( arg, writeId3v2Tag( tag ) ~ file );
				}

				// Print tag
				writeln( "Filename:\t", baseName( arg ) );
				if( tag.title.length > 0 )
					writeln( "Title:\t\t", tag.title );
				if( tag.artist.length > 0 )
					writeln( "Artist:\t\t", tag.artist );
				if( tag.performer.length > 0 )
					writeln( "Performer:\t", tag.performer );
				if( tag.album.length > 0 )
					writeln( "Album:\t\t", tag.album );
				if( tag.track > 0 )
					writeln( "Track#:\t\t", tag.track );
				if( tag.genre.length > 0 )
					writeln( "Genre:\t\t", tag.genre );
				if( tag.disc > 0 )
					writeln( "Disc#:\t\t", tag.disc );
				if( tag.year > 0 )
					writeln( "Year:\t\t", tag.year );
				if( tag.comment.length > 0 )
					writeln( "Comment:\t", tag.comment );
				if( tag.timestamp.length > 0 )
					writeln( "Timestamp:\t", tag.timestamp );
				writeln( "Cover:\t\t", ( tag.cover.length > 0 ) );
				writeln();
			}
			catch( Exception err )
			{
				stderr.writeln( "ERROR: ", err.msg );
				stderr.writeln( "ERROR: Problem processing \"", arg, "\"!" );
				exitStatus = 1;
			}
		}
	}
	catch( Exception err )
	{
		stderr.writeln( "ERROR: ", err.msg );
		stderr.writeln( "ERROR: Fatal error occurred!" );
		exitStatus = 1;
	}

	if( exitStatus != 0 )
		stderr.writeln( "Exiting with failure ..." );

	return exitStatus;
}

// vim: ts=4:sw=4:noet:si
