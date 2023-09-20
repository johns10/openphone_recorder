export default PaymentSetup = {
  mounted() {
    const successCallback = setupIntent => {
      this.pushEventTo('#payment-element', 'payment-setup', setupIntent)
    }
    init(this.el, successCallback)
  }
}

const init = (form, successCallback) => {
  const clientSecret = form.dataset.secret
  const accountId = form.dataset.accountId
  const publicKey = form.dataset.publicKey
  if (clientSecret && publicKey) {
    const stripe = Stripe(publicKey)
    var elements = stripe.elements({ clientSecret, appearance });
    var payment = elements.create('payment');
    payment.mount('#payment-element');

    payment.on('change', function (event) {
      var displayError = document.getElementById('card-errors');
      if (event.error) {
        document.getElementById('submit-payment').removeAttribute('disabled')
        displayError.textContent = event.error.message;
      } else {
        document.getElementById('submit-payment').removeAttribute('disabled')
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
}

const appearance = {
  theme: 'night'
}