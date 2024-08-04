// import 'package:discord_dart_bot/discord_dart_bot.dart' as discord_dart_bot;

import 'package:dotenv/dotenv.dart';
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

      await event.message.channel.sendMessage(
        MessageBuilder(embeds: [
          EmbedBuilder(
            author: EmbedAuthorBuilder(
              name: event.message.author.username,
              iconUrl: event.message.author.avatar?.url,
            ),
            description: newContent,
            color: DiscordColor.parseHexString('7C6EBB'),
          ),
        ]),
      );

      for (final link in parsedLinks) {
        await event.message.channel.sendMessage(MessageBuilder(
          content:
              '[${parsedLinks.length == 1 ? '.' : 'Link ${parsedLinks.indexOf(link) + 1}'}]($link)',
        ));
      }
    }
  });
}
