import 'dart:async';
import 'dart:convert';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart';
import 'package:nyxx/nyxx.dart';

void main(List<String> arguments) async {
  final env = DotEnv()..load();
  // print('Hello world: ${discord_dart_bot.calculate()}!');
  final client = await Nyxx.connectGateway(
    env['DISCORD_TOKEN'] ?? 'missing_key',
    GatewayIntents.allUnprivileged | GatewayIntents.messageContent,
    options: GatewayClientOptions(plugins: [logging, cliIntegration]),
  );

  final botUser = await client.users.fetchCurrentUser();

  final endpoint = Uri.parse(
    'https://api.catarse.me/project_details?project_id=eq.178796',
  );
  final response = await get(endpoint);
  final [{'pledged': pledged}] = jsonDecode(response.body) as List;
  const targets = {
    790000: '+5 Distinções de Heróis (25)',
    925000: 'Novas Ameaças: Gênios',
    1115000: 'Mundos dos Deuses em Cartelas (4)',
    1150000: 'Tokens das Novas Ameaças',
    1205000: 'Mais Poderes de Classes 1/2',
    1260000: '+5 Distinções de Devotos (15)',
    1350000: '+4 Cartelas de Mundos (8)',
    1375000: 'Trilhas Sonoras Artonianas',
    1415000: '+5 Distinções de Heróis (30)',
    1455000: 'Novas Ameaças: Fadas',
    1495000: '+4 Cartelas de Mundos (12)',
    1530000: 'Anúncio Surpresa + Brinde Digital',
    1560000: 'Culinária Avançada',
    1595000: '+5 Distinções de Devotos (20)',
    1635000: '+4 Cartelas de Mundos (16)',
    1725000: 'Guia de Deuses Menores (Digital)',
    1760000: 'Mais Poderes de Classes 2/2',
    1795000: 'Nova Linhagem de Feiticeiro: Abençoado',
    1815000: 'Cartelas Digitais',
    1855000: '+5 Distinções de Heróis (35)',
    1900000: 'Novas Ameaças: Gigantes',
    1990000: '+4 Cartelas de Mundos (20)',
    2326485: 'Guia de Deuses Menores (Físico)',
  };

  final successTargets =
      targets.entries.where((t) => t.key <= pledged).map((t) => t.value);
  var nextTarget = successTargets.length;

  final catarseMessage =
      'Iniciando acompanhamento da Campanha :dragon_face:\n${successTargets.map((t) => ':white_check_mark: $t').join('\n')}';
  const rpgChannel = Snowflake(1026722770333204511);
  client.channels.fetch(rpgChannel).then((channel) => (channel as TextChannel)
      .sendMessage(MessageBuilder(content: catarseMessage)));

  Timer.periodic(const Duration(seconds: 15), (_) async {
    print('Tá rodando a parte q é de tempos em tempos');
    final nextEntry = targets.entries.elementAt(nextTarget);
    final response = await get(endpoint);
    final [{'pledged': pledged}] = jsonDecode(response.body) as List;
    if (pledged >= nextEntry.key) {
      nextTarget++;
      client.channels.fetch(rpgChannel).then(
            (channel) => (channel as TextChannel).sendMessage(
              MessageBuilder(
                content:
                    'Nova meta alcançada! :tada:\n:white_check_mark: ${nextEntry.value}',
              ),
            ),
          );
    }
  });

  client.onMessageCreate.listen((event) async {
    if (event.member?.id == botUser.id) return;

    final twitterPattern = RegExp(
      r'https:\/\/(?:x|twitter).com\/([^\s?]*)(?:\?s=.*&t=[^\s]*)?',
    );

    if (twitterPattern.hasMatch(event.message.content)) {
      await event.message.delete();

      final parsedLinks = <String>[];
      final newContent = event.message.content.replaceAllMapped(
        twitterPattern,
        (match) {
          final newLink = 'https://fixupx.com/${match.group(1)}';
          parsedLinks.add(newLink);
          return '~~[Link ${parsedLinks.length}](${newLink.replaceFirst('fixup', '')})~~';
        },
      );

      var lastMessage = await event.message.channel.sendMessage(
        MessageBuilder(
          replyId: event.message.reference?.messageId,
          embeds: [
            EmbedBuilder(
              author: EmbedAuthorBuilder(
                name: event.message.author.username,
                iconUrl: event.message.author.avatar?.url,
              ),
              description: newContent,
              color: DiscordColor.parseHexString('7C6EBB'),
            ),
          ],
        ),
      );

      for (final link in parsedLinks) {
        lastMessage = await event.message.channel.sendMessage(MessageBuilder(
          replyId: lastMessage.id,
          content:
              '[${parsedLinks.length == 1 ? '.' : 'Link ${parsedLinks.indexOf(link) + 1}'}]($link)',
        ));
      }

      await lastMessage.react(
        ReactionBuilder(name: ':sus', id: Snowflake(941130823514615888)),
      );
    }
  });

  client.onMessageReactionAdd.listen((event) async {
    if (event.member?.id == botUser.id) return;
    final reactedMessage = await event.message.get();

    // if (event.emoji.name == '🔍') {
    //   print(reactedMessage);
    //   print('=============[embeds]=============');
    //   for (final embed in reactedMessage.embeds) {
    //     print('Author: ${embed.author}');
    //     print('Color: ${embed.color}');
    //     print('Description: ${embed.description}');
    //     print('Fields: ${embed.fields}');
    //     print('Footer: ${embed.footer}');
    //     print('Image: ${embed.image}');
    //     print('Provider: ${embed.provider}');
    //     print('Thumbnail: ${embed.thumbnail}');
    //     print('Timestamp: ${embed.timestamp}');
    //     print('Title: ${embed.title}');
    //     print('URL: ${embed.url}');
    //     print('Video: ${embed.video}');
    //   }
    //   return;
    // }

    if (event.emoji.id != Snowflake(941130823514615888)) return;
    if (event.messageAuthorId != botUser.id) return;

    var currentMessage = reactedMessage;
    final messagesToDelete = [currentMessage];
    while (currentMessage.reference != null) {
      final referencedMessage =
          (await currentMessage.reference?.message?.get())!;
      if (referencedMessage.author.id == botUser.id) {
        messagesToDelete.insert(0, referencedMessage);
        if (referencedMessage.content == '') {
          break;
        }
        currentMessage = referencedMessage;
      }
    }

    if (messagesToDelete.first.embeds.first.author?.name ==
        event.member?.user?.username) {
      for (final message in messagesToDelete) {
        await message.delete();
      }
    }
  });
}
