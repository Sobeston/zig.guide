import React, { type ComponentType } from "react";
import { processAdmonitionProps } from "@docusaurus/theme-common";
import type { Props } from "@theme/Admonition";
import AdmonitionTypes from "@theme/Admonition/Types";

function getAdmonitionTypeComponent(type: string): ComponentType<Props> {
  const component = AdmonitionTypes[type];

  console.log(AdmonitionTypes[type]);
  if (component) {
    return component;
  }
  console.warn(
    `No admonition component found for admonition type "${type}". Using Info as fallback.`
  );
  return AdmonitionTypes.info!;
}

export default function Admonition(unprocessedProps: Props): JSX.Element {
  const props = processAdmonitionProps(unprocessedProps);
  const AdmonitionTypeComponent = getAdmonitionTypeComponent(props.type);
  return <AdmonitionTypeComponent {...props} />;
}
