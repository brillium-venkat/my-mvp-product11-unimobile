// Fix for the bug - https://github.com/microsoft/TypeScript/issues/45612
interface Navigator {
  msSaveOrOpenBlob: (blob: Blob) => void;
}
