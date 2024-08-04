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
      r'https:\/\/x.com\/([^\s?]*)(?:\?s=.*&t=[^\s]*)?',
    );

    if (twitterPattern.hasMatch(event.message.content)) {
      final newContent = event.message.content.replaceAllMapped(
        twitterPattern,
        (match) => 'https://fixupx.com/${match.group(1)}',
      );

      final userName = event.message.author.username;
      await event.message.channel.sendMessage(
        MessageBuilder(content: '$newContent\n**by $userName**'),
      );
      await event.message.delete();
    }
  });
}
