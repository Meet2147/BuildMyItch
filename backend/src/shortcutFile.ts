// Serialises a generated shortcut into Apple's .shortcut format — a standard
// property list (XML plist) with a WFWorkflowActions array.
//
// Since iOS 15 the Shortcuts app only imports files signed by Apple, so the
// file we produce is for users who can sign it on a Mac
// (`shortcuts sign -m anyone -i in.shortcut -o out.shortcut`). The always-works
// path is the step-by-step guide the app shows alongside the download.

export type PlistValue =
  | string
  | number
  | boolean
  | PlistValue[]
  | { [key: string]: PlistValue };

function esc(s: string) {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

function node(value: PlistValue, indent: string): string {
  if (typeof value === "string") return `${indent}<string>${esc(value)}</string>`;
  if (typeof value === "boolean") return `${indent}<${value}/>`;
  if (typeof value === "number") {
    return Number.isInteger(value)
      ? `${indent}<integer>${value}</integer>`
      : `${indent}<real>${value}</real>`;
  }
  if (Array.isArray(value)) {
    if (value.length === 0) return `${indent}<array/>`;
    const inner = value.map((v) => node(v, indent + "\t")).join("\n");
    return `${indent}<array>\n${inner}\n${indent}</array>`;
  }
  const keys = Object.keys(value);
  if (keys.length === 0) return `${indent}<dict/>`;
  const inner = keys
    .map((k) => `${indent}\t<key>${esc(k)}</key>\n${node(value[k], indent + "\t")}`)
    .join("\n");
  return `${indent}<dict>\n${inner}\n${indent}</dict>`;
}

export function toPlist(root: PlistValue): string {
  return (
    '<?xml version="1.0" encoding="UTF-8"?>\n' +
    '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n' +
    '<plist version="1.0">\n' +
    node(root, "") +
    "\n</plist>\n"
  );
}

// Standard "accepts anything" input classes, same as a fresh shortcut made in the app.
const INPUT_CLASSES = [
  "WFAppStoreAppContentItem",
  "WFArticleContentItem",
  "WFContactContentItem",
  "WFDateContentItem",
  "WFEmailAddressContentItem",
  "WFGenericFileContentItem",
  "WFImageContentItem",
  "WFiTunesProductContentItem",
  "WFLocationContentItem",
  "WFDCMapsLinkContentItem",
  "WFAVAssetContentItem",
  "WFPDFContentItem",
  "WFPhoneNumberContentItem",
  "WFRichTextContentItem",
  "WFSafariWebPageContentItem",
  "WFStringContentItem",
  "WFURLContentItem",
];

export interface WorkflowAction {
  identifier: string;
  parameters: Record<string, PlistValue>;
}

export function buildShortcutFile(actions: WorkflowAction[]): string {
  return toPlist({
    WFWorkflowClientVersion: "1230.6",
    WFWorkflowMinimumClientVersion: 900,
    WFWorkflowMinimumClientVersionString: "900",
    WFWorkflowIcon: {
      WFWorkflowIconStartColor: 2071128575, // Shortcuts palette purple
      WFWorkflowIconGlyphNumber: 59511, // lightning bolt
    },
    WFWorkflowImportQuestions: [],
    WFWorkflowTypes: ["NCWidget", "WatchKit"],
    WFWorkflowInputContentItemClasses: INPUT_CLASSES,
    WFWorkflowActions: actions.map((a) => ({
      WFWorkflowActionIdentifier: a.identifier,
      WFWorkflowActionParameters: a.parameters,
    })),
  });
}
