# mPosit : modified Posit number representation for efficient decoding and encoding

Posit number system was proposed to be used as an alternative to the IEEE-754 
standard floating-point number format by Gustafson.
We propose a modified Posit format(mPosit) to modify Posit format for efficient decoding and encoding.

The mPosit decoder and encoder are developed in a parameterized Verilog HDL.
We also compare the mPosit decoder and encoder with several Posit decoders and encoders 
whose source codes are available in github.

1. mposit : mPosit decoder and encoder
2. posit : our designed posit decoder and encoder
3. PACoGen : posit decoder and encoder in PACoGen (https://github.com/manish-kj/PACoGen)
4. PDPU : posit decoder and encoder in PDPU (https://github.com/qleenju/PDPU)
