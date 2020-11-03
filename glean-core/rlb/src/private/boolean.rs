// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

use inherent::inherent;
use std::sync::Arc;

use glean_core::metrics::MetricType;

use crate::dispatcher;

// We need to wrap the glean-core type: otherwise if we try to implement
// the trait for the metric in `glean_core::metrics` we hit error[E0117]:
// only traits defined in the current crate can be implemented for arbitrary
// types.

/// This implements the developer facing API for recording boolean metrics.
///
/// Instances of this class type are automatically generated by the parsers
/// at build time, allowing developers to record values that were previously
/// registered in the metrics.yaml file.
#[derive(Clone)]
pub struct BooleanMetric(pub(crate) Arc<glean_core::metrics::BooleanMetric>);

impl BooleanMetric {
    /// The public constructor used by automatically generated metrics.
    pub fn new(meta: glean_core::CommonMetricData) -> Self {
        Self(Arc::new(glean_core::metrics::BooleanMetric::new(meta)))
    }
}

#[inherent(pub)]
impl glean_core::traits::Boolean for BooleanMetric {
    /// Sets to the specified boolean value.
    ///
    /// # Arguments
    ///
    /// * `value` - the value to set.
    fn set(&self, value: bool) {
        let metric = Arc::clone(&self.0);
        dispatcher::launch(move || crate::with_glean(|glean| metric.set(glean, value)));
    }

    /// **Exported for test purposes.**
    ///
    /// Gets the currently stored value as a boolean.
    ///
    /// This doesn't clear the stored value.
    ///
    /// # Arguments
    ///
    /// * `ping_name` - represents the optional name of the ping to retrieve the
    ///   metric for. Defaults to the first value in `send_in_pings`.
    fn test_get_value<'a, S: Into<Option<&'a str>>>(&self, ping_name: S) -> Option<bool> {
        dispatcher::block_on_queue();

        let queried_ping_name = match ping_name.into() {
            Some(name) => name,
            None => self.0.meta().send_in_pings.first().unwrap(),
        };

        crate::with_glean(|glean| self.0.test_get_value(glean, queried_ping_name))
    }
}
