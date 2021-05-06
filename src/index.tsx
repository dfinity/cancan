import React from "react";
import ReactDOM from "react-dom";
import { updateHead, ProvideAuth } from "./utils";
import { AppRouter } from "./AppRouter";
import "./styles.scss";

function CanCanApp() {
  return (
    <ProvideAuth>
      <AppRouter />
    </ProvideAuth>
  );
}

// Required for website to behave like a phone app on mobile devices
updateHead(document);

ReactDOM.render(<CanCanApp />, document.getElementById("app"));
