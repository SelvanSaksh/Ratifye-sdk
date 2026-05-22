import React from 'react';
import {
  NativeSyntheticEvent,
  requireNativeComponent,
  StyleSheet,
  ViewStyle,
} from 'react-native';

export type RatifyeScanSurface = 'single' | 'multi';

export type RatifyeScanEventKind =
  | 'single'
  | 'auth_success'
  | 'auth_failure'
  | 'multi'
  | 'camera_error';

/**
 * Auth configuration — every value comes from your app (env, API, session).
 * Do not hardcode URLs or company IDs in the SDK; pass them here at runtime.
 */
export type RatifyeAuthScanProps = {
  authScanEnabled?: boolean;
  /** From app config, e.g. Config.SCAN_AUTH_URL or login response */
  ingestURL?: string;
  bearerToken?: string;
  apiKey?: string;
  /** From app session / tenant, e.g. user.companyId */
  companyId?: string;
  ingestFormat?: 'auth_bc' | 'authBc' | 'legacy';
  extraHTTPHeaders?: Record<string, string>;
};

export type RatifyeScanEvent = {
  kind: RatifyeScanEventKind;
  surface?: RatifyeScanSurface;
  payload?: string;
  symbologyRaw?: string;
  scan?: { payload: string; symbologyRaw: string };
  auth?: {
    success?: boolean;
    httpStatus?: number;
    responseBody?: string;
    responseJSON?: Record<string, unknown>;
    errorCode?: string;
    errorMessage?: string;
  };
  errorCode?: string;
  errorMessage?: string;
};

type NativeSingleProps = RatifyeAuthScanProps & {
  style?: ViewStyle;
  singleScanEnabled?: boolean;
  onScanEvent?: (event: NativeSyntheticEvent<RatifyeScanEvent>) => void;
};

type NativeMultiProps = RatifyeAuthScanProps & {
  style?: ViewStyle;
  multiScanEnabled?: boolean;
  onScanEvent?: (event: NativeSyntheticEvent<RatifyeScanEvent>) => void;
};

const RatifyeSingleScanViewNative =
  requireNativeComponent<NativeSingleProps>('RatifyeSingleScanView');

const RatifyeMultiScanViewNative =
  requireNativeComponent<NativeMultiProps>('RatifyeMultiScanView');

function nativeAuthProps(auth: RatifyeAuthScanProps): Partial<RatifyeAuthScanProps> {
  const out: Partial<RatifyeAuthScanProps> = {};
  if (auth.authScanEnabled !== undefined) out.authScanEnabled = auth.authScanEnabled;
  if (auth.ingestURL !== undefined) out.ingestURL = auth.ingestURL;
  if (auth.bearerToken !== undefined) out.bearerToken = auth.bearerToken;
  if (auth.apiKey !== undefined) out.apiKey = auth.apiKey;
  if (auth.companyId !== undefined) out.companyId = auth.companyId;
  if (auth.ingestFormat !== undefined) out.ingestFormat = auth.ingestFormat;
  if (auth.extraHTTPHeaders !== undefined) out.extraHTTPHeaders = auth.extraHTTPHeaders;
  return out;
}

/** Page-embedded single camera. Pass auth URL/token/companyId from your app config only. */
export function RatifyeSingleScanCamera(
  props: RatifyeAuthScanProps & {
    singleScanEnabled?: boolean;
    onScanEvent: (event: RatifyeScanEvent) => void;
    style?: ViewStyle;
  }
) {
  const { singleScanEnabled, onScanEvent, style, ...auth } = props;

  return (
    <RatifyeSingleScanViewNative
      style={[styles.camera, style]}
      singleScanEnabled={singleScanEnabled}
      {...nativeAuthProps(auth)}
      onScanEvent={(e) => onScanEvent(e.nativeEvent)}
    />
  );
}

/** Page-embedded multi camera. Same dynamic auth props as single. */
export function RatifyeMultiScanCamera(
  props: RatifyeAuthScanProps & {
    multiScanEnabled?: boolean;
    onScanEvent: (event: RatifyeScanEvent) => void;
    style?: ViewStyle;
  }
) {
  const { multiScanEnabled, onScanEvent, style, ...auth } = props;

  return (
    <RatifyeMultiScanViewNative
      style={[styles.camera, style]}
      multiScanEnabled={multiScanEnabled}
      {...nativeAuthProps(auth)}
      onScanEvent={(e) => onScanEvent(e.nativeEvent)}
    />
  );
}

const styles = StyleSheet.create({
  camera: { flex: 1 },
});
