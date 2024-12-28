import React from "react";
import AdmonitionTypeNote from "@theme/Admonition/Type/Note";
import AdmonitionTypeTip from "@theme/Admonition/Type/Tip";
import AdmonitionTypeCpp from "@theme/Admonition/Type/Cpp";
import AdmonitionTypeInfo from "@theme/Admonition/Type/Info";
import AdmonitionTypeWarning from "@theme/Admonition/Type/Warning";
import AdmonitionTypeDanger from "@theme/Admonition/Type/Danger";
import AdmonitionTypeCaution from "@theme/Admonition/Type/Caution";

import type AdmonitionTypes from "@theme/Admonition/Types";

const admonitionTypes: typeof AdmonitionTypes = {
  note: AdmonitionTypeNote,
  tip: AdmonitionTypeTip,
  info: AdmonitionTypeInfo,
  warning: AdmonitionTypeWarning,
  danger: AdmonitionTypeDanger,
  cpp: AdmonitionTypeCpp,
};

// Undocumented legacy admonition type aliases
// Provide hardcoded/untranslated retrocompatible label
// See also https://github.com/facebook/docusaurus/issues/7767
const admonitionAliases: typeof AdmonitionTypes = {
  secondary: (props) => <AdmonitionTypeNote title="secondary" {...props} />,
  important: (props) => <AdmonitionTypeInfo title="important" {...props} />,
  success: (props) => <AdmonitionTypeTip title="success" {...props} />,
  caution: AdmonitionTypeCaution,
};

export default {
  ...admonitionTypes,
  ...admonitionAliases,
};
