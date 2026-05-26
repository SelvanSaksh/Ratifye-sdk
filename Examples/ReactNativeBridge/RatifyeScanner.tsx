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

export type RatifyeParsedBarcode = {
  barcode_data: string;
  encrypted_text: string;
  company_id: string;
};

export type RatifyeScanEvent = {
  kind: RatifyeScanEventKind;
  surface?: RatifyeScanSurface;
  /** Raw scanner string (includes GS1 segments). */
  payload?: string;
  symbologyRaw?: string;
  /** Base URL without `(98)…(97)…` segments. */
  barcode_data?: string;
  encrypted_text?: string;
  /** Taken from value after `(97)` in the barcode. */
  company_id?: string;
  parsed?: RatifyeParsedBarcode;
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

type NativeSingleProps = {
  style?: ViewStyle;
  singleScanEnabled?: boolean;
  authScanEnabled?: boolean;
  onScanEvent?: (event: NativeSyntheticEvent<RatifyeScanEvent>) => void;
};

type NativeMultiProps = {
  style?: ViewStyle;
  multiScanEnabled?: boolean;
  authScanEnabled?: boolean;
  onScanEvent?: (event: NativeSyntheticEvent<RatifyeScanEvent>) => void;
};

const RatifyeSingleScanViewNative =
  requireNativeComponent<NativeSingleProps>('RatifyeSingleScanView');

const RatifyeMultiScanViewNative =
  requireNativeComponent<NativeMultiProps>('RatifyeMultiScanView');

/**
 * Single-scan camera. Auth API URL and company_id are fixed inside the SDK.
 * App only toggles `singleScanEnabled` and `authScanEnabled`.
 */
export function RatifyeSingleScanCamera(props: {
  singleScanEnabled?: boolean;
  authScanEnabled?: boolean;
  onScanEvent: (event: RatifyeScanEvent) => void;
  style?: ViewStyle;
}) {
  const { singleScanEnabled, authScanEnabled, onScanEvent, style } = props;

  return (
    <RatifyeSingleScanViewNative
      style={[styles.camera, style]}
      singleScanEnabled={singleScanEnabled}
      authScanEnabled={authScanEnabled}
      onScanEvent={(e) => onScanEvent(e.nativeEvent)}
    />
  );
}

/**
 * Multi-scan camera. Same built-in auth endpoint when `authScanEnabled` is true.
 */
export function RatifyeMultiScanCamera(props: {
  multiScanEnabled?: boolean;
  authScanEnabled?: boolean;
  onScanEvent: (event: RatifyeScanEvent) => void;
  style?: ViewStyle;
}) {
  const { multiScanEnabled, authScanEnabled, onScanEvent, style } = props;

  return (
    <RatifyeMultiScanViewNative
      style={[styles.camera, style]}
      multiScanEnabled={multiScanEnabled}
      authScanEnabled={authScanEnabled}
      onScanEvent={(e) => onScanEvent(e.nativeEvent)}
    />
  );
}

const styles = StyleSheet.create({
  /** Parent screen must also use flex:1 or the native preview stays 0×0 (black). */
  camera: { flex: 1, minHeight: 200 },
});
