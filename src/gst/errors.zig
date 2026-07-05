pub const GStreamerError = error{
    InitializationFailed,
    PipelineCreationFailed,
    ElementCreationFailed,
    ParseError,
    BusNotFound,
    NoErrorInMessage,
    InvalidCapsString,
    GstMacOsMainFailed,
};
