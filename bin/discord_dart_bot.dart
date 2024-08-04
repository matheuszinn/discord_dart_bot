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
    print('message: ${event.message.content}');
    if (event.mentions.contains(botUser)) {
      await event.message.channel.sendMessage(
        MessageBuilder(content: 'Hi', replyId: event.message.id),
      );

      if (event.message.content.startsWith('ping')) {
        await event.message.delete();
      }
    }
  });
}
