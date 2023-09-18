// The public key can be found in the Stripe Dashboard
const stripe = Stripe('pk_live_51NJe4fD6og6lHPCfQRWiYjgbPRrjPkiVSoYxu8VbwE6RwLWldQpuTCw0rJUrh8lKa3eakgCi0yRqfqEouA5ckxUW00KUXEkvtc')

export default PaymentSetup = {
  mounted() {
    const successCallback = setupIntent => {
      this.pushEventTo('#payment-element', 'payment-setup', setupIntent)
    }
    init(this.el, successCallback)
  }
}

const init = (form, successCallback) => {
  console.log(form.dataset)
  const clientSecret = form.dataset.secret
  const accountId = form.dataset.accountId
  var elements = stripe.elements({ clientSecret, appearance });
  var payment = elements.create('payment');
  payment.mount('#payment-element');

  payment.on('change', function (event) {
    var displayError = document.getElementById('card-errors');
    if (event.error) {
      displayError.textContent = event.error.message;
    } else {
      displayError.textContent = '';
    }
  });

  // Handle form submission.
  form.addEventListener('submit', function (event) {
    event.preventDefault()

    stripe.confirmSetup({
      elements,
      confirmParams: { return_url: `${window.location.origin}/accounts/${accountId}` },
      redirect: 'if_required'
    }).then(function (result) {
      if (result.error) {
        console.log(result.error.message);
      } else {
        if (result.setupIntent.status === 'succeeded') {
          successCallback(result.setupIntent)
        }
      }
    })
    document.getElementById("submit-payment").setAttribute("disabled", true)
  })
}

const appearance = {
  theme: 'night',
  labels: 'floating'
}