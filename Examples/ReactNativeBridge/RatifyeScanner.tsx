import React, { useCallback, useState } from 'react';
import {
  Modal,
  NativeSyntheticEvent,
  StyleSheet,
  Text,
  View,
  requireNativeComponent,
} from 'react-native';

export type RatifyeScanSurface = 'single' | 'multi';

export type RatifyeScanEventKind =
  | 'single'
  | 'auth_success'
  | 'auth_failure'
  | 'multi'
  | 'camera_error';

/** Auth props shared by single- and multi-scan cameras. */
export type RatifyeAuthScanProps = {
  authScanEnabled?: boolean;
  ingestURL?: string;
  bearerToken?: string;
  apiKey?: string;
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
  style?: object;
  singleScanEnabled?: boolean;
  onScanEvent?: (event: NativeSyntheticEvent<RatifyeScanEvent>) => void;
};

type NativeMultiProps = RatifyeAuthScanProps & {
  style?: object;
  multiScanEnabled?: boolean;
  onScanEvent?: (event: NativeSyntheticEvent<RatifyeScanEvent>) => void;
};

const RatifyeSingleScanViewNative =
  requireNativeComponent<NativeSingleProps>('RatifyeSingleScanView');

const RatifyeMultiScanViewNative =
  requireNativeComponent<NativeMultiProps>('RatifyeMultiScanView');

/** Page-embedded single camera (plain and/or authenticated ingest). */
export function RatifyeSingleScanCamera(
  props: RatifyeAuthScanProps & {
    singleScanEnabled?: boolean;
    onScanEvent: (event: RatifyeScanEvent) => void;
    style?: object;
  }
) {
  const {
    singleScanEnabled = true,
    authScanEnabled = false,
    ingestURL,
    bearerToken,
    apiKey,
    extraHTTPHeaders,
    onScanEvent,
    style,
  } = props;

  return (
    <RatifyeSingleScanViewNative
      style={[styles.camera, style]}
      singleScanEnabled={singleScanEnabled}
      authScanEnabled={authScanEnabled}
      ingestURL={ingestURL}
      bearerToken={bearerToken}
      apiKey={apiKey}
      extraHTTPHeaders={extraHTTPHeaders}
      onScanEvent={(e) => onScanEvent(e.nativeEvent)}
    />
  );
}

/** Page-embedded multi camera (plain and/or authenticated ingest per scan). */
export function RatifyeMultiScanCamera(
  props: RatifyeAuthScanProps & {
    multiScanEnabled?: boolean;
    onScanEvent: (event: RatifyeScanEvent) => void;
    style?: object;
  }
) {
  const {
    multiScanEnabled = true,
    authScanEnabled = false,
    ingestURL,
    bearerToken,
    apiKey,
    extraHTTPHeaders,
    onScanEvent,
    style,
  } = props;

  return (
    <RatifyeMultiScanViewNative
      style={[styles.camera, style]}
      multiScanEnabled={multiScanEnabled}
      authScanEnabled={authScanEnabled}
      ingestURL={ingestURL}
      bearerToken={bearerToken}
      apiKey={apiKey}
      extraHTTPHeaders={extraHTTPHeaders}
      onScanEvent={(e) => onScanEvent(e.nativeEvent)}
    />
  );
}

/**
 * Example: camera on the page; auth works on both surfaces via the same props.
 * When authScanEnabled + ingestURL are set, each scan POSTs to your API and returns auth_success / auth_failure.
 */
export function RatifyeScannerExampleScreen() {
  const [useMultiScreen, setUseMultiScreen] = useState(false);
  const [authScanEnabled, setAuthScanEnabled] = useState(true);
  const [lastEvent, setLastEvent] = useState<RatifyeScanEvent | null>(null);
  const [sheetVisible, setSheetVisible] = useState(false);

  const authProps: RatifyeAuthScanProps = {
    authScanEnabled,
    ingestURL: authScanEnabled ? 'https://api.example.com/v1/scans' : undefined,
    bearerToken: authScanEnabled ? 'YOUR_TOKEN' : undefined,
  };

  const onScanEvent = useCallback((event: RatifyeScanEvent) => {
    setLastEvent(event);
    setSheetVisible(true);
  }, []);

  return (
    <View style={styles.screen}>
      {useMultiScreen ? (
        <RatifyeMultiScanCamera
          {...authProps}
          multiScanEnabled
          onScanEvent={onScanEvent}
        />
      ) : (
        <RatifyeSingleScanCamera
          {...authProps}
          singleScanEnabled={!authScanEnabled}
          onScanEvent={onScanEvent}
        />
      )}

      <Modal visible={sheetVisible} animationType="slide" transparent>
        <View style={styles.sheetBackdrop}>
          <View style={styles.sheet}>
            <Text style={styles.sheetTitle}>
              {lastEvent?.kind} ({lastEvent?.surface})
            </Text>
            <Text selectable>{JSON.stringify(lastEvent, null, 2)}</Text>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: '#000' },
  camera: { flex: 1 },
  sheetBackdrop: {
    flex: 1,
    justifyContent: 'flex-end',
    backgroundColor: 'rgba(0,0,0,0.4)',
  },
  sheet: {
    maxHeight: '50%',
    backgroundColor: '#fff',
    padding: 16,
    borderTopLeftRadius: 12,
    borderTopRightRadius: 12,
  },
  sheetTitle: { fontSize: 18, fontWeight: '600', marginBottom: 8 },
});
