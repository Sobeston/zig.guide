import React, { Children } from "react";
import clsx from "clsx";
import Translate from "@docusaurus/Translate";
import type { Props } from "@theme/Admonition/Type/Tip";
import AdmonitionLayout, {
  AdmonitionContainer,
  AdmonitionHeading,
  AdmonitionContent,
} from "@theme/Admonition/Layout";
import AdmonitionIconJs from "@theme/Admonition/Icon/Js";

const infimaClassName = "alert alert--info";

const defaultProps = {
  icon: <AdmonitionIconJs />,
  title: (
    <Translate
      id="theme.admonition.js"
      description="The default label used for the Js admonition (:::js)"
    >
      Coming from Javascript?
    </Translate>
  ),
};

export default function AdmonitionTypeJs(props: Props): JSX.Element {
  const {
    type,
    icon = defaultProps.icon,
    title = defaultProps.title,
    children,
    className,
  } = props;

  return (
    <AdmonitionContainer
      type={type}
      className={clsx(infimaClassName, className)}
    >
      <details>
        <summary
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <div style={{ display: "flex", alignItems: "center" }}>
            {title || icon ? (
              <AdmonitionHeading title={title} icon={icon} />
            ) : null}
          </div>
          <span style={{ marginLeft: "auto" }}>&#9660;</span>
        </summary>

        <AdmonitionContent>{children}</AdmonitionContent>
      </details>
    </AdmonitionContainer>
  );
}
