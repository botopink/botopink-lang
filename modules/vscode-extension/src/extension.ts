import * as fs from "fs";
import * as path from "path";
import * as vscode from "vscode";
import { workspace } from "vscode";
import {
  LanguageClient,
  LanguageClientOptions,
  ServerOptions,
} from "vscode-languageclient/node";

const enum BotopinkCommands {
  RestartServer = "botopink.restartServer",
}

const EXTENSION_NS = "botopink";
const DEFAULT_SERVER_BIN = "botopink-lsp";

let client: LanguageClient | undefined;
let configureLang: vscode.Disposable | undefined;

export async function activate(context: vscode.ExtensionContext) {
  const onEnterRules = [...continueTypingCommentsOnNewline()];

  configureLang = vscode.languages.setLanguageConfiguration("botopink", {
    onEnterRules,
  });

  const restartCommand = vscode.commands.registerCommand(
    BotopinkCommands.RestartServer,
    async () => {
      if (!client) {
        vscode.window.showErrorMessage("botopink client not found");
        return;
      }

      try {
        if (client.isRunning()) {
          await client.restart();
          vscode.window.showInformationMessage("botopink server restarted.");
        } else {
          await client.start();
        }
      } catch (err) {
        client.error("Restarting client failed", err, "force");
      }
    },
  );

  context.subscriptions.push(restartCommand);

  client = await createLanguageClient();
  client?.start();
}

export function deactivate(): Thenable<void> | undefined {
  configureLang?.dispose();
  return client?.stop();
}

async function createLanguageClient(): Promise<LanguageClient | undefined> {
  const command = await getBotopinkLspPath();
  if (!command) {
    const message = `Could not resolve the botopink-lsp executable. Ensure it is on the PATH used by VS Code, or set "botopink.path" to a valid executable.`;
    vscode.window.showErrorMessage(message);
    return;
  }

  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: "file", language: "botopink" }],
    synchronize: {
      fileEvents: [
        workspace.createFileSystemWatcher("**/*.bp"),
        workspace.createFileSystemWatcher("**/build.zig"),
      ],
    },
  };

  const serverOptions: ServerOptions = {
    command,
    args: [],
    options: {
      env: Object.assign({}, process.env),
    },
  };

  return new LanguageClient(
    "botopink_language_server",
    "Botopink Language Server",
    serverOptions,
    clientOptions,
  );
}

/**
 * `OnEnterRule`s to continue doc comments when pressing Enter.
 * Mirrors botopink's `//`, `///`, `////` comment levels.
 */
function continueTypingCommentsOnNewline(): vscode.OnEnterRule[] {
  const indentAction = vscode.IndentAction.None;
  return [
    {
      beforeText: /^\s*\/{4}.*$/,
      action: { indentAction, appendText: "//// " },
    },
    {
      beforeText: /^\s*\/{3}.*$/,
      action: { indentAction, appendText: "/// " },
    },
  ];
}

/** Returns the absolute path to the botopink-lsp command, or the bare name. */
export async function getBotopinkLspPath(): Promise<string | undefined> {
  const configured = getWorkspaceConfigLspPath();
  const workspaceFolders = vscode.workspace.workspaceFolders;
  if (!configured || !workspaceFolders) {
    return configured ?? DEFAULT_SERVER_BIN;
  } else if (!path.isAbsolute(configured)) {
    for (const folder of workspaceFolders) {
      const candidate = path.resolve(folder.uri.fsPath, configured);
      if (await fileExists(candidate)) {
        return candidate;
      }
    }
    return undefined;
  }
  return configured;
}

function getWorkspaceConfigLspPath(): string | undefined {
  const exePath = vscode.workspace.getConfiguration(EXTENSION_NS).get("path");
  if (typeof exePath !== "string" || !exePath || exePath.trim().length === 0) {
    return undefined;
  }
  return exePath;
}

function fileExists(executableFilePath: string): Promise<boolean> {
  return new Promise<boolean>((resolve) => {
    fs.stat(executableFilePath, (err, stat) => {
      resolve(err == null && stat.isFile());
    });
  }).catch(() => false);
}
